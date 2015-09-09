# Copyright (C) 2015 Pombe LLC - All Rights Reserved

Promise = require "bluebird"
bluebirdDelay = require "bluebird-delay"

bluebirdRetry = (fn, opt = {}) ->
    currentAttemptPromise = null
    nextInterval = opt.interval
    if opt.max_tries then attemptsLeft = opt.max_tries
    if opt.timeout then endTime = Date.now() + opt.timeout

    return new Promise (resolve, reject) ->
        tryOnce = (delay) ->
            if !opt.use_delay then startTime = new Date()

            if delay? then promise = bluebirdDelay(delay, { unref: opt.unref }).then () -> fn()
            else promise = Promise.try fn
            
            promise.cancellable()
            .then (rv) -> resolve(rv)
            .catch (err) ->
                now = Date.now()

                if err.endRetry || # Error was flagged for ending the retry
                   attemptsLeft == 1 || # Out of attempts
                   err.name == "CancellationError" || # Was canceled - do not use instanceof because we may have multiple bluebirds around
                   (endTime && endTime <= now) # Out of time
                    reject err
                    return

                if attemptsLeft then attemptsLeft--

                # Make interval calculations if needed
                if nextInterval
                    # Stash current interval
                    thisDelay = nextInterval

                    # Offset for fn() execution time (if using intervals and not delay)
                    if !opt.use_delay then thisDelay -= startTime - now

                    # Increase backoff for next delay
                    if opt.backoff
                        nextInterval *= opt.backoff
                        if opt.max_interval then nextInterval = Math.min nextInterval, opt.max_interval

                # And make the next attempt
                if thisDelay > 0
                    # Final check to make sure the timeout will not pass while in the delay
                    if now + thisDelay > endTime
                        reject err
                        return

                currentAttemptPromise = tryOnce (thisDelay || 0)
                return # Ensure we do not return the tryOnce promise

        currentAttemptPromise = tryOnce()

    .cancellable()
    .catch (err) ->
        currentAttemptPromise.cancel err if err.name == "CancellationError"
        throw err




module.exports = bluebirdRetry
