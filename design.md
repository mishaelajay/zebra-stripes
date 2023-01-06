I have used rails for this solution.
However, i used the --minimal option and removed all unwanted dependencies and folders.

There are 4 different services:

### PathValidator

This service take in two arguments:
- *path* : the path to the file or directory
- *type* : can be either 'file' or 'dir'
-
It returns true if the given path exists and false if it does not.


### CsvWriter

CsvWriter is a service that takes care of write operations to any given csv.
In our case it will be used to write customers into a csv file.

This service takes in two arguments:
- *directory_path* : The directory where the customers csv should be stored
- *filename* : The name that must be given to the csv

This service has the following methods:
|Methods| Usage  |
|--|--|
|*push_headers*| Creates the csv and pushes the first row of headers into the created csv |
|*push_batch(customers)*| Pushes a given array of customers into the csv|
|*full_path*| Provides a fullpath to the csv file by appending directory_path and filename params.


### Throttler

Throttler is a service that helps in controlling the number of requests sent within a given timespan. It successfully prevents rate limit errors.

Throttler uses a dedicated Redis cache db. It sets a counter with an expiry of n seconds and updates this counter for each request that is made. The counter is reset every n seconds. It provides the time to wait in milliseconds (for extra accuracy) so that we know when we can make the next request without being rate limited.

Throttler takes in 2 arguments:
- *requests_allowed* : The number requests allowed in a particular timespan
- *reset_in_seconds* : The timespan within which requests_allowed should be reset

This service has the following methods:
|Methods| Usage  |
|--|--|
|*increment_counter*| It increments the counter in cache by 1 if the counter is already set. If not, it will set the counter with a value of 1 and expiry time of *reset_in_seconds* param.	 |
|*current_counter_value*| Returns the current counter value|
|*throttle?*| Returns true or false depending on whether the cache counter value exceeds *requests_allowed*
|*throttle_for_in_milliseconds*| Returns the time remaining for the counter to reset in milliseconds using redis *pttl* function.

### CustomersFetcher

The CustomersFetcher service is where the actual call to Stripe api is made. I have made use of the already available official [Stripe ruby client](https://github.com/stripe/stripe-ruby) instead of rewriting my own api wrapper.

The service fetches customers in batches of 50 and stores the last customer id in a dedicated cache db (*PAGE_TRACKER_CACHE*) under the key 'current_starting_after'. When the next fifty is needed, this service will fetch the current_starting_after from db and hit the api again with *starting_after* param to fetch the next 50 customers. It returns the has_more field along with the customers so as to indicate when all customers have been fetched.

CustomersFetcher does not take any arguments. The api key is fetched from Rails credential file. I have sent the master key  in my response email for the task. Please make sure to create a master.key file and paste the key i sent in the file.

The CustomersFetcher provides the following methods:
|Methods| Usage  |
|--|--|
|*next_fifty_customers*| It will return the next_fifty_customers using the *current_starting_after* value from cache if needed.	 |
|*list_customers*| Makes the actual api call|
|*get_starting_after*| Returns the *current_starting_after* value set in cache.
|*set_starting_after*| Returns the time remaining for the counter to reset in milliseconds using redis *pttl* function.
|*flush_tracking_cache*| Flushes the page_tracking_cache db.

## CustomersFetchWorker

This worker works as follows:
1: Fetches 50 customers at a time using the *CustomersFetcher* service
2: Checks if rate limit has been exceeded using *throttle?* method provided by *Throttler*
3: If rate limit is exceeded it will sleep for the seconds *throttler_for_in_milliseconds* method provided by Throttler.
4: If not, it will fetch the next 50 customers.
5: After every successful fetch, it will write the response to a Redis queue. The pages will then be popped by CsvWriteWorker while writing to the csv.
6: After all pages have been fetched it will trigger CsvWriteWorker.

## CsvWriteWorker

1: It will fetch the customers populated by CustomersFetchWorker from the Redis queue by popping them one by one.
2: It will write each popped set of customers to the csv file.
3: It will exit once all customer pages in the queue have been written to the csv.

## The main rake task : save_stripe_customers_to_csv

The rake task takes in one argument.

- *target_directory* : The path to the directory where the csv will be stored.


1. The rake task first checks for *target_directory* validity using PathValidator service.
2. It then triggers the **CustomersFetchWorker** which on completion will trigger the **CsvWriteWorker**


### Test Coverage
I have covered all exceptions and services with essential but minimal test cases.
Given more time, more test cases can be added. The rake task is not covered with test cases.

### Advantages of this solution:

- Never gets rate limited, thanks to the Throttler service
- Since the api calls are made from a sidekiq worker and is tracked via a dedicated redis cache db, retrying the worker will not result in duplicate calls to the api. It would continue from where it left of as stated in the requirements.
- The CustomersFetchWorker will push 50 customers at a time to a Redis queue instead of directly writing to the file which saves time (opening, writing each time we have a set of customers).
- The Csv writing is in an independent worker which pops customers the Redis queue and writes them to the file in one go. Since it fetches them from the cache, it is really quick.
- Both the workers can be made idempotent.

### Drawbacks of this solution:

- I have not written the solution in a way where multiple workers can work in parallel due to **lack of time**, however it is really simple to add that feature. All that is needed would be a unique id for each rake task run which can be used as a part of the redis keys, making sure each worker runs independently.
- Sidekiq and redis dependency.
- Race conditions due to redis.


### Improvements

- More test coverage
- Using a table to keep track of each rake task run and its status.
- Notifying the user via email/sms etc once the workers are done.
- Accepting the fields that should be saved from the user instead of hardcoding it.
	
