expect = require("chai").expect
Promise = require "bluebird"

describe "Shutdown Handler", () ->
    bluebirdRetry = require "../lib/bluebirdRetry"

    it "should just work with nothing set", (cb) ->
        n = 0
        fn = () ->
            n++
            throw new Error "unitTest" if n < 10

        bluebirdRetry fn
        .then () -> cb()

    it "should honor max tries", (cb) ->
        n = 0
        fn = () ->
            n++
            throw new Error "unitTest"

        bluebirdRetry fn, max_tries: 10
        .catch (err) ->
            expect(err.message).to.equal("unitTest")
            expect(n).to.equal(10)
            cb()

    it "should honor timeout", (cb) ->
        n = 0
        fn = () ->
            n++
            throw new Error "unitTest"

        bluebirdRetry fn, timeout: 25
        .catch (err) ->
            expect(err.message).to.equal("unitTest")
            cb()

    it "should properly use interval", (cb) ->
        n = 0
        fn = () ->
            n++
            if n < 5 then return Promise.delay(5).then () -> throw new Error "unitTest"

        start = Date.now()
        bluebirdRetry fn, interval: 5
        .then () ->
            delay = Date.now() - start
            expect(n).to.equal(5)
            expect(delay).to.be.gte(45)
            cb()

    it "should properly use use_delay", (cb) ->
        n = 0
        fn = () ->
            n++
            if n < 5 then return Promise.delay(5).then () -> throw new Error "unitTest"

        start = Date.now()
        bluebirdRetry fn, { interval: 5, use_delay: true }
        .then () ->
            delay = Date.now() - start
            expect(n).to.equal(5)
            expect(delay).to.be.gte(20).and.lt(50)
            cb()

    it "should properly use backoff", (cb) ->
        n = 0
        fn = () ->
            n++
            if n < 4 then throw new Error "unitTest"

        start = Date.now()
        bluebirdRetry fn, { interval: 5, backoff: 2 }
        .then () ->
            delay = Date.now() - start
            expect(n).to.equal(4)
            expect(delay).to.be.gte(35)
            cb()

    it "should properly use backoff", (cb) ->
        n = 0
        fn = () ->
            n++
            if n < 4 then throw new Error "unitTest"

        start = Date.now()
        bluebirdRetry fn, { interval: 1, backoff: 2, max_interval: 2 }
        .then () ->
            delay = Date.now() - start
            expect(n).to.equal(4)
            expect(delay).to.be.gte(7).and.lt(35)
            cb()

    it "should properly reject when backoff will exceed timeout", (cb) ->
        n = 0
        fn = () ->
            n++
            if n < 4 then throw new Error "unitTest"

        start = Date.now()
        bluebirdRetry fn, { interval: 1, backoff: 10000000, timeout: 25 }
        .catch (err) ->
            expect(err.message).to.equal("unitTest")
            cb()

    it "should support unref", (cb) ->
        n = 0
        fn = () ->
            n++
            if n < 5 then throw new Error "unitTest"

        start = Date.now()
        bluebirdRetry fn, { interval: 5, unref: true }
        .then () -> cb()
        # @todo Any easy and useful way to ensure unref worked?

    it "should support cancellation", (cb) ->
        fn = () -> throw new Error "unitTest"
        p = bluebirdRetry fn, interval: 5000
        .catch Promise.CancellationError, () -> cb()
        setTimeout (() -> p.cancel()), 35

    it "should support cancellation (no interval)", (cb) ->
        fn = () -> throw new Error "unitTest"
        p = bluebirdRetry fn
        .catch Promise.CancellationError, () -> cb()
        setTimeout (() -> p.cancel()), 35

    it "should support cancellation (with external exception)", (cb) ->
        ex = new Error
        ex.name = "CancellationError"

        fn = () -> throw new Error "unitTest"
        p = bluebirdRetry fn, interval: 5000
        .catch (err) ->
            throw err if err != ex
            cb()

        setTimeout (() -> p.cancel(ex)), 35

