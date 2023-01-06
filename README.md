Please refer to [Design.md](https://github.com/mishaelajay/zebra-stripes/blob/main/Design.md) for technical details and code run through.

# Installation

The app uses `ruby 2.6.9`. Make sure you have it installed from [ruby official site](https://www.ruby-lang.org/en/downloads/)

Clone the repository on your local:

    git@github.com:mishaelajay/zebra-stripes.git

Create a file called master.key and pasted the master key in it.

```touch master.key```

Navigate to the `zebra-stripes` folder and run bundler.

    bundle install

Install redis on your local

    brew install redis

Make sure redis is running as a service on the default port 6379

    brew services start redis

In a separate terminal, start the sidekiq process by running the following command. Do not close this terminal.

    bundle exec sidekiq
To download customers, first create a target directory if you dont already have one:

    mkdir stripe_csv
    

Now you can run the main rake task to download images as follows.

    rake 'save_stripe_customers_to_csv[<target_directory>]

Replace <target_directory> with the path to your target directory 

On running the rake task, your download will be processed in the background. The sidekiq terminal will ring a
notification bell on completion. Your file should be present in the target directory with a timestamp.

Possible Errors:

- InvalidPathError: This is thrown when either of the path arguments do not point to a dir or a file.

To run the test suite just run:

```rspec spec/```
s
