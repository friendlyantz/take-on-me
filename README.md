# take-on-me

challenge with your friends to complete the tasks you always wanted to accomplish

# TODO

- Services (job queues, cache servers, search engines, etc.)
- Deployment instructions
- mise - <https://mise.jdx.dev/>

# Tools

- rails latest
- Postgres
- docker
- Kamal

- Rspec
- Tailwind / DaisyUI
- SitePrism

# Debugging

```ruby
gem "debugger"

debugger(binding)

# ----------
gem "trace_location"

request = Rack::MockRequest.env_for('http://localhost:3000')

was_alloc = GC.stat[:total_allocated_objects] # the number of created Ruby objects

TraceLocation.trace(format: :log, methods: [:call]) do
  Rails.application.call(request)
end

new_alloc = GC.stat[:total_allocated_objects]
puts "Total allocations: #{new_alloc - was_alloc}"
```
