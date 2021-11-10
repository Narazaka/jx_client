# JxClient

日本におけるインターネットEDI（電子データ交換）において利用されるJX手順通信ライブラリ

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jx_client'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install jx_client

## Usage

```ruby
require "jx_client"

client = JxClient.new(
  jx_version: 2007,
  jx_message_id_generate: -> { "#{SecureRandom.hex}@example.com" },
  jx_timestamp_generate: true,
  jx_default_options: {
    from: "sender.example.com",
  },
  endpoint: "receiver.example.com", # Savon options
)

client.put_document do |op|
  op.options(
    to: "receiver.example.com",
    data: "123,なにか,456\n",
    sender_id: "10001",
    receiver_id: "10002",
    format_type: "SecondGenEDI",
    document_type: "Order",
  )
  MyPutDocumentStore.mark_sending(op.sent_options)
  count = 0
  begin
    count += 1
    op.call
  rescue Savon::Error
    retry if count < 4
    raise
  end
  MyPutDocumentStore.mark_sent(op.sent_options)
end

get_document = client.get_document do |op|
  op.options(
    to: "receiver.example.com",
    receiver_id: "10001",
  )
  count = 0
  begin
    count += 1
    op.call
  rescue Savon::Error
    retry if count < 4
    raise
  end
  MyGetDocumentStore.mark_received(op.response.result)
  MyApp.receive_document(op.response.result)
  MyGetDocumentStore.mark_app_processed(op.response.result)
end

client.confirm_document do |op|
  op.options(
    to: "receiver.example.com",
    sender_id: "10001",
    receiver_id: "10002",
    message_id: get_document.result.message_id,
  )
  count = 0
  begin
    count += 1
    op.call
  rescue Savon::Error
    retry if count < 4
    raise
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Narazaka/jx_client.

## License

This is released under [Zlib License](LICENSE).
