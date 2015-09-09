[![bUild Status](https://travis-ci.org/UberEther/bluebird-cancellable-retry.svg?branch=master)](https://travis-ci.org/UberEther/bluebird-cancellable-retry)
[![NPM Status](https://badge.fury.io/js/bluebird-cancellable-retry.svg)](http://badge.fury.io/js/bluebird-cancellable-retry)

# Overview

This library provides a [Bluebird](https://github.com/petkaantonov/bluebird) promise method to retry an action while allowing cancellation.

While I was initially using [bluebird-retry](https://github.com/jut-io/bluebird-retry), I encountered issues needing to unreference and/or cancel promises which were retrying.  As I had a couple other edge conditions, I authored a slightly different package instead of trying to adapt that one.

# Examples of use:

```
var Promise = require("bluebird");
var bluebirdRetry = require("bluebird-cancellable-retry");

function doWork() {
	// Some method that does work but possibly throws an exception
	// May return a promise
}

/*
This will now call doWork and if it fails, wait 1 second and retry.
It will repeat this up to 10 times or 5 minutes.
The delays will increase each attempt - 1, 2, 4, 8, and then 10 seconds each time after that
If you get tired of waiting, you can call: p1.cancel();
*/
var p1 = bluebirdRetry(doWork, { interval: 1000, use_delay: true, max_tries: 10, timeout: 300000, backoff: 2, max_interval: 10 });
.then(function () { /* Do something with the results here */ });
```

# API

## bluebirdRetry(method, options)

Executes the specified method and retries as defined by the options until it succeedes or runs out of attempts.  The method may return a promise.

If the method throws an error or returns a promise that is rejected, the error is inspected to see what to do.
- If the error has a property "endRetry" set to a truthy value, then the retry loop is terminated and the error thrown
- If the error is a bluebird CancellationError, then the retry loop is terminated and the error thrown
- If we are out of time or attempts, the error is thrown
- Otherwise the method is retried after any specified delay

Options:
- interval - Interval (in milliseconds) of executions
    - If not specified, there will be no delay between attempts
	- if use_delay is set to true, then this is a delay from one failure till the next attempt
	- otherwise it is the interval from the start of one attept to the start of the next (assuming the first one fails)
- use_delay - See notes under "interval" above
- max_tries - Maximum number of attempts - if not specified, then the number of attempts is not limited
- timeout - Maximum total time (in milliseconds) to try - will not be time limited if not specified
- backoff - If set, then the interval will be multiplied by this value after each failure
	- Setting to 1.0 is same as not setting it at all
	- Setting to a value less than 1.0 will make each attempt faster instead of slower
	- Setting to a negative value would just be silly...
- max_interval - If backoff is set, the interval will be capped at this value
- unref - If set to true, the delay timer is unreferenced so that the timer does not prevent Node from exiting

# Contributing

Any PRs are welcome but please stick to following the general style of the code and stick to [CoffeeScript](http://coffeescript.org/).  I know the opinions on CoffeeScript are...highly varied...I will not go into this debate here - this project is currently written in CoffeeScript and I ask you maintain that for any PRs.

