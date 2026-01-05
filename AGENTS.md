# AGENTS.md: Rails Code Generation Standards

This document guides AI code generation for Rails applications built at Evil Martians. It's designed for founders, designers, and PMs who use Claude, GitHub Copilot, or other AI tools to build maintainable Rails code without needing a senior engineer to refactor everything.

**Core Principle:** Generated code should be so simple and clear that reading it feels like reading well-written documentation. Elegant. Self-explanatory.

---

## Project Overview

We build Rails applications that prioritize **simplicity, clarity, and maintainability**. We trust Rails conventions rather than fighting them. We name things after business domains, not technical patterns. We avoid over-architecture.

Generated code should:
- Follow Rails conventions (not fight the framework)
- Use domain language (Participant, not User; Cloud, not GeneratedImage)
- Keep logic at the right layer (models handle data, controllers handle HTTP, jobs coordinate workflows)
- Be readable without comments
- Normalize data properly (separate concerns into tables, not columns)

---

## Technology Stack & Gems

**Only use these gems.** If you want to add something not listed, ask in a clarifying comment.

### Core Rails & Server
- `rails` (latest stable)
- `puma` (default)
- `propshaft` (asset pipeline)

### Database & Data
- `activerecord` (included)
- `pg` (PostgreSQL)
- `store_model` (type-safe JSON columns, when needed)

### Frontend
- `hotwire-rails` (Turbo + Stimulus, included)
- `view_component` (reusable UI components)
- `vite_rails` (modern JS/CSS bundling with hot reload)
- `bundlebun` (Node-as-a-gem runtime)

### Jobs & Background Work
- `solid_queue` (default)

### Authentication & Authorization
- built-in authentication (generator)
- `omniauth` (for OAuth)
- `action_policy` (for complex authorization)

### Configuration
- `anyway_config` (type-safe configuration from environment)
- Don't use: Rails credentials, ENV variables directly

### Testing
- `rspec-rails` (not minitest)
- `factory_bot_rails` (test data)
- `faker` (realistic fake data)
- `test_prof` (for faster tests)

### Code Quality
- `standard` (Ruby linting—replaces Rubocop)
- `prettier` (JavaScript formatting, if you have JS)

### IDs & Slugs
- `nanoid` (short, URL-safe IDs)
- `friendly_id` (SEO-friendly slugs)

### HTTP & API
- `httparty` (clean, readable HTTP requests)
- Don't use: Faraday, RestClient

### Admin
- `avo` (modern Rails admin panel, if you need it)

### Error Tracking
- `sentry-rails` (error reporting—optional)

**Don't use:**
- Service objects (services/)
- Context objects (contexts/)
- Use case / operation / interactor gems
- Custom authentication modules
- Concerns for business logic
- Devise
- CanCanCan
- ActiveAdmin
- Complex state machine gems (use enums)
- Virtus, Literal, dry-types, reform (use plain models)

---

## File Structure & Organization

### Folder Layout

```
app/
├── models/
│   ├── application_record.rb
│   ├── participant.rb
│   ├── cloud.rb
│   ├── cloud/
│   │   ├── card_generator.rb      # Namespaced under model
│   │   ├── nsfw_detector.rb
│   │   └── query.rb
│   ├── invitation.rb
│   ├── invitation/
│   │   └── mailer.rb
│   └── application_query.rb        # Base class for queries
├── controllers/
│   ├── application_controller.rb
│   ├── clouds_controller.rb
│   ├── participant/                # Namespace for scoped routes
│   │   ├── application_controller.rb
│   │   ├── clouds_controller.rb
│   │   └── homes_controller.rb
│   └── webhooks/
│       └── mandrill_controller.rb
├── jobs/
│   ├── application_job.rb
│   └── cloud_generation_job.rb
├── forms/                          # Only when creating multiple models
│   ├── application_form.rb
│   └── participant_registration_form.rb
├── mailers/
│   ├── application_mailer.rb
│   └── invitation_mailer.rb
├── policies/                       # Only when complex authorization is needed
│   ├── application_policy.rb
│   └── cloud_policy.rb
├── views/
│   ├── clouds/
│   ├── participant/
│   │   ├── clouds/
│   │   └── homes/
│   ├── layouts/
│   └── components/                 # ViewComponent components
│       └── cloud_card.html.erb
└── frontend/                       # If using Vite
    ├── entrypoints/
    ├── controllers/                # Stimulus controllers
    └── styles/

config/
├── configs/                        # anyway_config classes
│   ├── application_config.rb
│   ├── gemini_config.rb
│   ├── smtp_config.rb
│   └── app_config.rb
├── database.yml
├── routes.rb
└── puma.rb

db/
├── migrate/
├── seeds.rb
└── schema.rb

spec/
├── models/
├── requests/                       # Controller tests
├── system/                         # Full-stack browser tests
├── factories/
├── support/
└── spec_helper.rb
```

**Critical rules:**
- No `app/services/` folder
- No `app/contexts/` folder
- No `app/operations/` folder
- Complex operations go in namespaced model classes: `Cloud::CardGenerator`
- Controllers are namespaced for authentication/scoping: `Participant::CloudsController`

---

## Model Patterns

### Naming: Use Domain Language

**Bad (Technical):**
```ruby
class User < ApplicationRecord
  has_many :generated_images
end

class GeneratedImage < ApplicationRecord
  belongs_to :user
end
```

**Good (Domain-appropriate):**
```ruby
class Participant < ApplicationRecord
  has_many :clouds, dependent: :destroy
  has_many :invitations, dependent: :destroy
end

class Cloud < ApplicationRecord
  belongs_to :participant
end

class Invitation < ApplicationRecord
  belongs_to :participant
end
```

Names should reflect the business domain. "Participant" is what they are at a conference. "Cloud" is what they generate. Not generic terms.

### Model Organization Order

Always follow this order in model files:

```ruby
class Cloud < ApplicationRecord
  # 1. Gems and DSL extensions
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  # 2. Associations
  belongs_to :participant
  has_many :invitations, dependent: :destroy
  has_one :latest_invitation, -> { order(created_at: :desc) }, class_name: "Invitation"

  # 3. Enums (for state)
  enum :state, %w[uploaded analyzing analyzed generating generated failed].index_by(&:itself)

  # 4. Normalization (Rails 8+)
  normalizes :name, with: ->(name) { name.strip }

  # 5. Validations
  validates :name, :state, presence: true
  validates :participant_id, presence: true

  # 6. Scopes
  scope :generated, -> { where(state: :generated) }
  scope :picked, -> { where(picked: true) }
  scope :recent, -> { order(created_at: :desc) }

  # 7. Callbacks
  before_create do
    self.state ||= :uploaded
  end

  # 8. Delegated methods
  delegate :email, to: :participant, prefix: true

  # 9. Public instance methods
  def ready_to_generate?
    analyzed? && !generating?
  end

  # 10. Private methods
  private

  def generate_filename
    "cloud-#{participant.slug}-#{id}.png"
  end
end
```

### Use Enums for State

**Always use enums for states.** No string columns like `status` or `state_string`.

```ruby
class Cloud < ApplicationRecord
  enum :state, %w[uploaded analyzing analyzed generating generated failed].index_by(&:itself)
end

# Usage:
cloud.uploaded?          # Predicate method
cloud.generating!        # Bang method (update + save)
Cloud.generated.count    # Scope
```

Why: Type-safe, gives you predicate methods for free, database-efficient.

### Use `normalizes` for Data Cleanup

**Rails 8 feature.** Automatically clean data before validation.

```ruby
class Participant < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }
end

# Before save:
participant = Participant.new(email: "  USER@EXAMPLE.COM  ")
participant.save
participant.email  # → "user@example.com"
```

### Thin Models, Smart Organization

**Model should not be 100+ lines.** If it is, extract to namespaced classes.

**Bad (Model too fat):**
```ruby
class Cloud < ApplicationRecord
  def generate_card_image
    # 50 lines of API logic
    # 20 lines of image processing
    # 30 lines of error handling
  end

  def check_nsfw
    # 40 lines of moderation logic
  end

  def upload_to_storage
    # 30 lines of storage logic
  end
end
```

**Good (Extracted to namespaced classes):**
```ruby
class Cloud < ApplicationRecord
  # Model: just data and simple methods
  def ready_to_generate?
    analyzed?
  end
end

class Cloud::CardGenerator
  def initialize(cloud, api_key: GeminiConfig.api_key)
    @cloud = cloud
    @api_key = api_key
  end

  def generate
    # Complex API logic here, returns IO object
  end
end

class Cloud::NSFWDetector
  def initialize(cloud, api_key: GeminiConfig.api_key)
    @cloud = cloud
    @api_key = api_key
  end

  def check
    # Moderation logic, returns true/false
  end
end
```

**When to extract:**
- Any method over 15 lines
- Any method calling external APIs
- Any complex calculation
- Anything reusable

**How to structure:**
```ruby
# app/models/cloud/card_generator.rb
class Cloud::CardGenerator
  private attr_reader :cloud, :api_key

  def initialize(cloud, api_key: GeminiConfig.api_key)
    @cloud = cloud
    @api_key = api_key
  end

  def generate
    # Public method that returns simple value or raises
    prompt = build_prompt
    response = call_api(prompt)
    decode_image(response)
  end

  private

  def build_prompt
    # ...
  end

  def call_api(prompt)
    # ...
  end

  def decode_image(response)
    # ...
  end
end
```

Use `private attr_reader` for internal state. Delegates to related objects. Returns simple values (IO, strings, booleans). Raises exceptions on error (don't return error objects).

### Use Counter Caches

**Every has_many should have a counter cache.**

```ruby
class Participant < ApplicationRecord
  has_many :clouds, dependent: :destroy
  has_many :invitations, dependent: :destroy
end

class Cloud < ApplicationRecord
  belongs_to :participant, counter_cache: true
end

class Invitation < ApplicationRecord
  belongs_to :participant, counter_cache: true
end

# No N+1 queries. Count is always up-to-date.
participant.clouds_count    # Fast, no query
participant.invitations_count
```

### Callbacks: Use Sparingly

**Callbacks are okay for simple things. Not for workflows.**

Good use:
```ruby
class Participant < ApplicationRecord
  before_create do
    self.access_token ||= Nanoid.generate(size: 6)
  end

  before_save do
    self.slug = nil if name_changed?  # Friendly ID will regenerate
  end
end
```

Bad use:
```ruby
# DON'T: Complex workflow in callback
class Cloud < ApplicationRecord
  after_create do
    CloudGenerationJob.perform_later(self)
    Mailer.notify_created(self).deliver_later
    Metrics.record_cloud_created(self)
  end
end
```

**Instead use:** A job or form object for workflows.

---

## Controller Patterns

### Keep Controllers Extremely Thin

**Target: 5-10 lines per action.** No business logic.

```ruby
class Participant::CloudsController < Participant::ApplicationController
  def new
    redirect_to home_path unless @participant.can_generate_cloud?
  end

  def create
    return head 422 unless @participant.can_generate_cloud?

    blob = ActiveStorage::Blob.find_signed(params[:cloud][:blob_signed_id])
    return head 422 unless blob

    cloud = @participant.clouds.create do
      it.image.attach(blob)
    end

    CloudGenerationJob.perform_later(cloud)

    redirect_to cloud_path(cloud)
  end

  def update
    cloud = @participant.clouds.find(params[:id])
    Cloud.transaction do
      @participant.clouds.update_all(picked: false)
      cloud.update_column(:picked, true)
    end

    redirect_to home_path
  end
end
```

**Action breakdown:**
- Guard clauses (early returns)
- Simple model operations (create, update)
- Job enqueueing
- Redirect/render

**No:**
- Business logic
- Complex conditionals
- Multiple model operations (use Form Object instead)
- Data transformation

### Use Namespace Controllers for Authentication/Scoping

**Pattern:**
```ruby
# app/controllers/participant/application_controller.rb
class Participant::ApplicationController < ::ApplicationController
  before_action :set_participant

  private

  def set_participant
    @participant = ::Participant.find_by!(access_token: params[:access_token])
  end
end

# app/controllers/participant/clouds_controller.rb
class Participant::CloudsController < Participant::ApplicationController
  # @participant is automatically set
  def index
    @clouds = @participant.clouds.recent
  end
end
```

All routes under `Participant::` are automatically scoped. No need for concerns or custom modules.

### Return Early, Use Guard Clauses

**Bad:**
```ruby
def create
  if user.premium?
    if params[:name].present?
      if validate_input
        cloud = create_cloud
        return redirect_to cloud
      end
    end
  end
  head 422
end
```

**Good:**
```ruby
def create
  return head 401 unless @participant.premium?
  return head 422 unless params[:name].present?
  return head 422 unless validate_input

  cloud = @participant.clouds.create!(params.permit(:name))
  redirect_to cloud
end
```

Guard clauses make the happy path obvious.

### Don't Use Concerns for Business Logic

**Bad:**
```ruby
module TokenAuthenticated
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_by_token!
  end

  def authenticate_by_token!
    # ...
  end
end

class CloudsController < ApplicationController
  include TokenAuthenticated
end
```

**Good:**
```ruby
class Participant::ApplicationController < ApplicationController
  before_action :set_participant

  private

  def set_participant
    @participant = Participant.find_by!(access_token: params[:access_token])
  end
end

class Participant::CloudsController < Participant::ApplicationController
  # Inheritance handles scoping, no magic
end
```

Inheritance is clearer than concerns.

---

## Database Design & Migrations

### Normalize Data: One Concern Per Table

**Bad (Denormalized):**
```ruby
create_table :participants do |t|
  t.string :email
  t.string :full_name
  t.datetime :invitation_sent_at
  t.datetime :invitation_opened_at
  t.string :bounce_type
  t.datetime :bounced_at
  t.boolean :invitation_resend_requested
  # Everything crammed together
end
```

**Good (Normalized):**
```ruby
create_table :participants do |t|
  t.string :email, null: false
  t.string :full_name, null: false
  t.string :access_token
  t.integer :cloud_generations_quota, default: 5
  t.integer :cloud_generations_count, default: 0
  t.integer :invitations_count, default: 0
  t.timestamps
end

create_table :invitations do |t|
  t.integer :participant_id, null: false, foreign_key: true
  t.enum :status, enum_type: :invitation_status, default: "sent"
  t.datetime :opened_at
  t.string :bounce_type
  t.datetime :bounced_at
  t.timestamps
end

create_table :clouds do |t|
  t.integer :participant_id, null: false, foreign_key: true
  t.enum :state, enum_type: :cloud_state, default: "uploaded"
  t.boolean :picked, default: false
  t.string :failure_reason
  t.timestamps
end
```

Each concern is a separate table. Easier to query, easier to extend, easier to analyze.

### Use Foreign Keys & Constraints

```ruby
create_table :clouds do |t|
  t.integer :participant_id, null: false
  t.foreign_key :participants, column: :participant_id, on_delete: :cascade
  t.enum :state, enum_type: :cloud_state, default: "uploaded", null: false
  t.timestamps
end

add_check_constraint :participants, "cloud_generations_count <= cloud_generations_quota"
```

Database enforces relationships and rules. Application bugs can't create invalid states.

### Use Counter Caches

```ruby
class CreateClouds < ActiveRecord::Migration[7.0]
  def change
    create_table :clouds do |t|
      t.integer :participant_id, null: false, foreign_key: true
      t.integer :participant_id
      t.foreign_key :participants, column: :participant_id
      t.timestamps
    end

    add_column :participants, :cloud_generations_count, :integer, default: 0, null: false
  end
end
```

Counter cache is a denormalization for performance. No N+1 queries.

### Enums in the Database

**Only in PostgreSQL**

```ruby
create_enum :cloud_state, ["uploaded", "analyzing", "analyzed", "generating", "generated", "failed"]
create_enum :invitation_status, ["sent", "opened", "bounced", "unsubscribed"]

create_table :clouds do |t|
  t.enum :state, enum_type: :cloud_state, default: "uploaded", null: false
end

create_table :invitations do |t|
  t.enum :status, enum_type: :invitation_status, default: "sent", null: false
end
```

Database-level enums prevent invalid states at the database layer.

---

## Job Patterns

### Use ActiveJob::Continuable for Multi-Step Workflows

**Pattern:**
```ruby

# app/jobs/cloud_generation_job.rb
class CloudGenerationJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(cloud)
    @cloud = cloud

    step :moderate, isolated: true
    step :generate, isolated: true unless cloud.failed?
  end

  private

  attr_reader :cloud

  def moderate(_step)
    cloud.update!(state: :analyzing)

    detector = Cloud::NSFWDetector.new(cloud)
    if detector.check
      cloud.update!(state: :analyzed)
    else
      cloud.update!(state: :failed, failure_reason: "NSFW content detected")
    end
  rescue => err
    Rails.error.report(err, handled: true)
    cloud.update!(state: :failed, failure_reason: err.message)
  end

  def generate(_step)
    cloud.update!(state: :generating)

    generator = Cloud::CardGenerator.new(cloud)
    io = generator.generate

    cloud.generated_image.attach(
      io:,
      filename: "cloud-#{cloud.participant.slug}.png",
      content_type: "image/png"
    )

    cloud.update!(state: :generated)

    Turbo::StreamsChannel.broadcast_refresh_to(cloud)
  rescue => err
    Rails.error.report(err, handled: true)
    cloud.update!(state: :failed, failure_reason: err.message)
  end
end
```

**Why this pattern:**
- Each step is isolated (errors don't crash the whole job)
- Conditional steps (skip generate if moderation fails)
- Clear state transitions
- Error handling is consistent
- Progress visible to UI (via Turbo Streams)
- Retryable steps

**Key features:**
- `include ActiveJob::Continuable`
- `step :method_name, isolated: true` defines each step
- `isolated: true` means errors are caught and logged, job continues (or fails cleanly)
- Update model state after each step
- Broadcast progress for real-time updates

### Jobs Orchestrate, Models Execute

**Good separation:**
```ruby
# Job orchestrates workflow
class CloudGenerationJob < ApplicationJob
  def perform(cloud)
    step :generate
  end

  private

  def generate(_step)
    generator = Cloud::CardGenerator.new(cloud)
    io = generator.generate  # Delegates to model class
    cloud.generated_image.attach(io:, filename: "...")
  end
end

# Model class executes business logic
class Cloud::CardGenerator
  def initialize(cloud)
    @cloud = cloud
  end

  def generate
    # Complex API/processing logic here
    # Returns IO object or raises exception
    StringIO.new(decoded_image_data)
  end

  private

  def build_prompt
    # ...
  end

  def call_api(prompt)
    # ...
  end
end
```

**Don't put complex logic in jobs.** Jobs are for orchestration. Model classes handle complexity.

### Error Handling in Jobs

```ruby
def moderate(_step)
  # Do work
  cloud.update!(state: :analyzed)
rescue => err
  Rails.error.report(err, handled: true)  # Sends to Sentry if configured
  cloud.update!(state: :failed, failure_reason: err.message)
end
```

Always:
- Catch errors with `rescue => err`
- Report to error tracking (Rails.error.report)
- Update model state to reflect failure
- Don't re-raise unless you want the entire job to fail

---

## Configuration Management

### Use anyway_config for Type-Safe Configuration

**Pattern:**
```ruby
# config/configs/application_config.rb
class ApplicationConfig < Anyway::Config
  class << self
    delegate_missing_to :instance

    private

    def instance
      @instance ||= new
    end
  end
end

# config/configs/gemini_config.rb
class GeminiConfig < ApplicationConfig
  attr_config :api_key
end

# config/configs/app_config.rb
class AppConfig < ApplicationConfig
  attr_config :host, :port,
    admin_username: "admin",
    admin_password: "pass"

  def ssl?
    port == 443
  end

  def asset_host
    super || begin
      proto = ssl? ? "https://" : "http://"
      "#{proto}#{host}"
    end
  end
end
```

**Usage:**
```ruby
GeminiConfig.api_key
AppConfig.host
AppConfig.ssl?
```

**Environment variables map automatically:**
```bash
GEMINI_API_KEY=xxx          # → GeminiConfig.api_key
APP_HOST=example.com        # → AppConfig.host
APP_PORT=443                # → AppConfig.port
```

**Why this approach:**
- Type-safe (validates on load)
- Singleton pattern (access anywhere)
- Organized in `config/configs/`
- Can add helper methods (ssl?, configured?)
- Environment-specific (development, test, production)

### Never use Rails credentials or ENV directly

**Bad:**
```ruby
api_key = ENV["GEMINI_API_KEY"]  # Error-prone, untyped

ENV.fetch("API_KEY", "default")  # Works, but no validation
```

**Good:**
```ruby
api_key = GeminiConfig.api_key  # Type-safe, organized, testable
```

---

## Form Objects

### Use Form Objects for Multi-Model Operations

**When:**
- Creating/updating multiple related records
- Complex validations across models
- Need transaction boundaries
- Want to decouple from controller

**Pattern:**
```ruby
# app/forms/application_form.rb
class ApplicationForm
  include ActiveModel::API
  include ActiveModel::Attributes
  include AfterCommitEverywhere

  define_callbacks :save, only: :after
  define_callbacks :commit, only: :after

  class << self
    def after_save(...)
      set_callback(:save, :after, ...)
    end

    def after_commit(...)
      set_callback(:commit, :after, ...)
    end

    def model_name
      @model_name ||= ActiveModel::Name.new(nil, nil, self.class.name.sub(/Form$/, ""))
    end
  end

  def save
    return false unless valid?

    with_transaction do
      after_commit { run_callbacks(:commit) }
      run_callbacks(:save) { submit! }
    end
  end

  private

  def with_transaction(&block)
    ApplicationRecord.transaction(&block)
  end

  def submit!
    raise NotImplementedError
  end
end

# app/forms/participant_registration_form.rb
class ParticipantRegistrationForm < ApplicationForm
  attribute :full_name, :string
  attribute :email, :string

  validates :full_name, :email, presence: true

  private

  def submit!
    participant = Participant.create!(
      full_name:,
      email:
    )

    invitation = participant.invitations.create!

    Mailer.send_invitation(invitation).deliver_later
  end
end
```

**In controller:**
```ruby
def create
  @form = ParticipantRegistrationForm.new(form_params)

  if @form.save
    redirect_to home_path
  else
    render :new
  end
end

private

def form_params
  params.require(:participant_registration_form).permit(:full_name, :email)
end
```

---

## Query Objects

### Use Query Objects for Complex Queries

**When:**
- Query has multiple conditions
- Query is reused across controllers
- Query is easier to test in isolation

**Pattern:**
```ruby
# app/models/application_query.rb
class ApplicationQuery
  class << self
    attr_writer :query_model_name

    def query_model_name
      @query_model_name ||= name.sub(/::[^:]+$/, "")
    end

    def query_model
      query_model_name.safe_constantize
    end

    def call(...)
      new.call(...)
    end
  end

  private attr_reader :relation

  def initialize(relation = self.class.query_model.all)
    @relation = relation
  end

  def call
    relation
  end
end

# app/models/participant/pending_query.rb
class Participant::PendingQuery < ApplicationQuery
  def call
    relation
      .without_picked_cloud
      .where(blocked: false)
      .order(created_at: :desc)
  end
end
```

**Usage:**
```ruby
# In controller
@pending = Participant::PendingQuery.call

# Or with a relation
@pending = Participant::PendingQuery.new(Participant.active).call
```

---

## View & Frontend Patterns

### Use Hotwire: Turbo + Stimulus

**Don't build SPAs.** Use Hotwire for interactivity.

**Turbo for page updates:**
```erb
<%= turbo_stream_from @cloud %>

<div id="<%= dom_id(@cloud) %>">
  <%= render "cloud", cloud: @cloud %>
</div>
```

```ruby
# In job or controller
cloud.update!(state: :generated)
Turbo::StreamsChannel.broadcast_refresh_to(cloud)
```

**Stimulus for JavaScript sprinkles:**
```erb
<div data-controller="timer">
  <button data-action="timer#start">Start</button>
  <span data-timer-target="display">0:00</span>
</div>
```

```javascript
// app/javascript/controllers/timer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]

  start() {
    // Timer logic
  }
}
```

### Use ViewComponent for Reusable UI

```ruby
# app/components/cloud_card_component.rb
class CloudCardComponent < ViewComponent::Base
  def initialize(cloud)
    @cloud = cloud
  end

  private

  attr_reader :cloud
end
```

```erb
<!-- app/components/cloud_card_component.html.erb -->
<div class="cloud-card" id="<%= dom_id(cloud) %>">
  <h3><%= cloud.name %></h3>
  <p><%= cloud.state %></p>
</div>
```

**Usage in views:**
```erb
<%= render CloudCardComponent.new(cloud) %>
```

### Database Queries from Views

**Good:** Simple associations and scopes
```erb
<% @participant.clouds.recent.each do |cloud| %>
  <%= render "cloud", cloud: %>
<% end %>
```

**Bad:** N+1 queries, complex logic in views
```erb
<!-- DON'T: complex query logic -->
<% @clouds.select { |c| c.participant.premium? && c.state.in?(%w[generated]) } %>
```

**Instead:** Query object or scope
```ruby
# Model
scope :recent, -> { order(created_at: :desc) }

# Controller
@clouds = @participant.clouds.recent

# View
<% @clouds.each do |cloud| %>
  <%= render "cloud", cloud: %>
<% end %>
```

---

## Testing Patterns

### RSpec > Minitest

Use RSpec for better DSL and readability.

### Test Organization

```
spec/
├── models/          # Model logic
├── requests/        # Controller/HTTP responses
├── system/          # Full-stack browser tests (excluded by default)
├── factories/
├── support/
└── spec_helper.rb
```

### Model Tests: Logic & Validations

```ruby
describe Cloud do
  describe "#ready_to_generate?" do
    it "returns true when analyzed" do
      cloud = create(:cloud, state: :analyzed)
      expect(cloud.ready_to_generate?).to be true
    end

    it "returns false when generating" do
      cloud = create(:cloud, state: :generating)
      expect(cloud.ready_to_generate?).to be false
    end
  end

  describe "validations" do
    it "validates presence of participant_id" do
      cloud = build(:cloud, participant_id: nil)
      expect(cloud).not_to be_valid
    end
  end
end
```

### Request Tests: HTTP Behavior

```ruby
describe "Participant::CloudsController" do
  describe "POST /participant/:access_token/clouds" do
    it "creates a cloud when user can generate" do
      participant = create(:participant)
      blob = create(:active_storage_blob)

      expect do
        post participant_clouds_path(access_token: participant.access_token),
          params: { cloud: { blob_signed_id: blob.signed_id } }
      end.to change(Cloud, :count).by(1)

      expect(response).to redirect_to(participant_cloud_path(participant.access_token, Cloud.last))
    end
  end
end
```

### System Tests: Critical User Flows

```ruby
describe "Cloud generation flow", type: :system do
  it "generates a cloud from upload to display" do
    participant = create(:participant)

    visit participant_home_path(access_token: participant.access_token)
    click_button "Upload Image"

    # Upload interaction, assertions...
    expect(page).to have_content "Cloud generated"
  end
end
```

**Tip:** Exclude system tests by default in `spec_helper.rb`:
```ruby
RSpec.configure do |config|
  config.filter_run_excluding type: :system
end
```

Run with: `rspec --tag type:system`

### Use FactoryBot for Test Data

```ruby
# spec/factories/participants.rb
FactoryBot.define do
  factory :participant do
    full_name { Faker::Name.name }
    email { Faker::Internet.email }

    trait :with_cloud do
      after(:create) do |participant|
        create(:cloud, participant:)
      end
    end
  end
end

# In tests
participant = create(:participant, :with_cloud)
```

### Don't Test Framework Behavior

**Skip these tests:**
- ActiveRecord callbacks (framework tests these)
- Basic CRUD (framework tests these)
- Model associations (too simple to break)
- Generated code (don't test the generator output)

**Test these:**
- Custom validations
- Business logic methods
- Controller responses
- Integration flows

---

## Routing

### RESTful Routes with Namespaces

```ruby
Rails.application.routes.draw do
  root "clouds#index"

  # Public routes
  resources :clouds, only: [:index, :show]

  # Participant-scoped routes
  scope "/c/:access_token", as: :participant, module: :participant do
    resource :home, only: [:show]
    resources :clouds
  end

  # Admin namespace
  mount Avo::Engine, at: Avo.configuration.root_path

  # Webhooks
  namespace :webhooks do
    resource :mandrill, only: [:create]
  end
end
```

**Route patterns:**
- RESTful resources (index, show, create, update, delete)
- Namespaces for logical grouping (admin, webhooks, participant)
- Scopes for parameter injection (:access_token available to all routes)
- Conditionally mount tools (dev-only, feature-flagged)

---

## Common Patterns & Anti-Patterns

### Pattern: Guard Clauses Over Nested Conditionals

**Bad:**
```ruby
def create
  if admin?
    if params[:valid]
      if check_limit
        create_object
      end
    end
  end
end
```

**Good:**
```ruby
def create
  return head 401 unless admin?
  return head 422 unless params[:valid]
  return head 429 unless check_limit
  create_object
end
```

### Pattern: Delegation Over Inheritance for Small Helpers

**Bad:**
```ruby
module EmailHelper
  def participant_email
    "#{@participant.slug}@example.com"
  end
end

class CloudsController < ApplicationController
  include EmailHelper
end
```

**Good:**
```ruby
class CloudsController < ApplicationController
  def email_address
    @participant.participant_email  # Delegate to model
  end
end

class Participant
  def participant_email
    "#{slug}@example.com"
  end
end
```

### Anti-Pattern: Service Objects

**Don't create `app/services/`:**
```ruby
# Bad
class ImageGenerationService
  def initialize(cloud)
    @cloud = cloud
  end

  def call
    # Logic here
  end
end
```

**Do this instead:**
- **Model method:** `cloud.generate_image!`
- **Namespaced class:** `Cloud::CardGenerator.new(cloud).generate`
- **Job:** `CloudGenerationJob.perform_later(cloud)`

### Anti-Pattern: Result Objects

**Don't use:**
```ruby
Result = Struct.new(:success?, :data, :error, keyword_init: true)

generator.call  # => Result.new(success?: true, data: io, error: nil)
```

**Do this instead:**
```ruby
generator.generate  # => returns IO, raises on error
```

Return simple values. Raise exceptions. Let the caller decide.

### Anti-Pattern: Passing Around Hashes

**Bad:**
```ruby
def create_cloud(params)
  { state: "generating", id: cloud.id, user_id: cloud.participant_id }
end

result = create_cloud(name: "test")
puts result[:state]
```

**Good:**
```ruby
def create_cloud(params)
  Participant.create!(**params)
end

cloud = create_cloud(name: "test")
puts cloud.state
```

Return objects, not hashes. Type-safe and IDE-friendly.

---

## Performance & Optimization

### Counter Caches: Use Them

```ruby
class Participant < ApplicationRecord
  has_many :clouds
  has_many :invitations
end

class Cloud < ApplicationRecord
  belongs_to :participant, counter_cache: true
end

# No N+1
participant.clouds_count  # Single column read, no query
```

### Scopes: Don't Use Complex Calculations

**Bad:**
```ruby
scope :active, -> {
  where("clouds.created_at > ?", Time.current - 30.days)
    .where("clouds.state = ? OR (clouds.state = ? AND clouds.updated_at > ?)",
      "generated", "generating", Time.current - 1.hour)
}
```

**Good:**
```ruby
scope :recent, -> { where("created_at > ?", 30.days.ago) }
scope :active, -> { where(state: [:generated, :generating]) }
scope :recently_active, -> { where("updated_at > ?", 1.hour.ago) }

# Compose scopes
Cloud.recent.active.recently_active
```

### N+1 Prevention

**Use eager loading:**
```ruby
# Bad: N+1 queries
Participant.all.each { |p| p.clouds.count }

# Good: 2 queries total
Participant.all.includes(:clouds)
```

### Indexes

```ruby
create_table :clouds do |t|
  t.integer :participant_id
  t.enum :state
  t.boolean :picked

  t.index [:participant_id, :state]  # Composite index
  t.index :picked
end
```

Index on:
- Foreign keys
- Frequently queried columns
- Enum state columns
- Columns in scopes

---

## Development Workflow

### Generators: What to Use

```bash
# Generate models with associations
rails generate model Cloud participant:references state:enum

# Generate controllers with actions
rails generate controller Participant::Clouds show create

# Generate jobs
rails generate job CloudGeneration

# Generate migrations
rails generate migration AddPickedToClouds picked:boolean
```

### What NOT to Generate

Don't use Rails generators for:
- Service objects (don't generate these)
- Scaffolding (too much boilerplate)
- Full CRUD (customize manually)

### Running Tests

```bash
# All tests
rspec

# Specific model
rspec spec/models/cloud_spec.rb

# Exclude system tests (slow)
rspec --tag ~type:system

# Only system tests
rspec --tag type:system

# Verbose output
rspec -f d
```

### Standard Ruby Linting

```bash
# Check style
bundle exec standardrb

# Fix automatically
bundle exec standardrb --fix
```

---

## Deployment & Production Readiness

### Environment Variables

```bash
# .env (development/test)
GEMINI_API_KEY=test-key
APP_HOST=localhost:3000
APP_PORT=3000

# .env.production
GEMINI_API_KEY=production-key
APP_HOST=sfruby.cloud
APP_PORT=443
```

### Database Constraints

Always add to migrations:
```ruby
add_null_constraint :clouds, :participant_id
add_check_constraint :participants, "cloud_generations_count <= cloud_generations_quota"
add_foreign_key :clouds, :participants, on_delete: :cascade
```

Database prevents invalid states.

### Error Tracking

```ruby
# Sentry (optional but recommended)
Sentry.init do |config|
  config.dsn = "https://xxxx@xxxx.ingest.sentry.io/xxxx"
  config.traces_sample_rate = 1.0
end

# In jobs/code
rescue => err
  Rails.error.report(err, handled: true)
end
```

---

## Summary: The Checklist

Before writing/generating code, ask:

- [ ] Is this named after a business domain concept (not technical)?
- [ ] Is the model organized in the right order (gems → associations → enums → validations → scopes)?
- [ ] Are states in enums, not string columns?
- [ ] Is the controller action under 10 lines?
- [ ] Is complex logic extracted to namespaced model classes (e.g., `Cloud::CardGenerator`)?
- [ ] Is the database normalized (one concern per table)?
- [ ] Are foreign keys and constraints added?
- [ ] Are counter caches used for has_many?
- [ ] Are workflows in jobs with `ActiveJob::Continuable`?
- [ ] Is configuration via `anyway_config`, not ENV?
- [ ] Are tests in RSpec, not minitest?
- [ ] Are views simple (scopes/associations, no complex logic)?

If yes to all: your code is ready to ship.

---

## Quick Reference

| Pattern | Location | When |
|---------|----------|------|
| Model method | `Cloud#ready_to_generate?` | Simple query or check |
| Namespaced class | `Cloud::CardGenerator` | Complex operation (>15 lines) |
| Scope | `Cloud.generated` | Reusable query |
| Job | `CloudGenerationJob` | Async workflow or steps |
| Form Object | `ParticipantRegistrationForm` | Multi-model create/update |
| Query Object | `Participant::PendingQuery` | Complex query |
| Controller action | `Participant::CloudsController#create` | HTTP handling only |
| View component | `CloudCardComponent` | Reusable UI |
| Config class | `GeminiConfig` | Configuration |

| Anti-Pattern | Why | Alternative |
|---|---|---|
| Service object | Unnecessary abstraction | Namespaced model class |
| Result object | Over-engineered | Return value or raise |
| Concern for logic | Magic, hard to trace | Inheritance or delegation |
| ENV variables | Untyped, scattered | anyway_config |
| String state | Type-unsafe | Enum |
| Denormalized schema | Harder to query/extend | Normalized with FK + constraints |
| Fat models | Hard to maintain | Extract to namespaced classes |
| Fat controllers | Hard to test | Thin controller + model method |
| Complex conditionals | Hard to read | Guard clauses |

---

## Need Help?

This AGENTS.md is designed for AI code generation. If your AI-generated code doesn't match these patterns:

1. **Paste the AGENTS.md into your prompt** when asking Claude/Copilot to generate Rails code
2. **Reference specific sections** ("Follow the Controller Patterns section")
3. **Show examples** of what you want (include a sample from sfruby-clouds if possible)

**Questions?** This guide is intentionally specific. The more constraints you give AI tools, the better code they generate.

---

**Version:** 1.0
**Last Updated:** December 2025
**Created by:** Evil Martians
**For:** Rails developers, founders, designers building with code generation

---

# daisyUI 5
daisyUI 5 is a CSS library for Tailwind CSS 4
daisyUI 5 provides class names for common UI components

- [daisyUI 5 docs](http://daisyui.com)
- [Guide: How to use this file in LLMs and code editors](https://daisyui.com/docs/editor/)
- [daisyUI 5 release notes](https://daisyui.com/docs/v5/)
- [daisyUI 4 to 5 upgrade guide](https://daisyui.com/docs/upgrade/)

## daisyUI 5 install notes
[install guide](https://daisyui.com/docs/install/)
1. daisyUI 5 requires Tailwind CSS 4
2. `tailwind.config.js` file is deprecated in Tailwind CSS v4. do not use `tailwind.config.js`. Tailwind CSS v4 only needs `@import "tailwindcss";` in the CSS file if it's a node dependency.
3. daisyUI 5 can be installed using `npm i -D daisyui@latest` and then adding `@plugin "daisyui";` to the CSS file
4. daisyUI is suggested to be installed as a dependency but if you really want to use it from CDN, you can use Tailwind CSS and daisyUI CDN files:
```html
<link href="https://cdn.jsdelivr.net/npm/daisyui@5" rel="stylesheet" type="text/css" />
<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
```
5. A CSS file with Tailwind CSS and daisyUI looks like this (if it's a node dependency)
```css
@import "tailwindcss";
@plugin "daisyui";
```

## daisyUI 5 usage rules
1. We can give styles to a HTML element by adding daisyUI class names to it. By adding a component class name, part class names (if there's any available for that component), and modifier class names (if there's any available for that component)
2. Components can be customized using Tailwind CSS utility classes if the customization is not possible using the existing daisyUI classes. For example `btn px-10` sets a custom horizontal padding to a `btn`
3. If customization of daisyUI styles using Tailwind CSS utility classes didn't work because of CSS specificity issues, you can use the `!` at the end of the Tailwind CSS utility class to override the existing styles. For example `btn bg-red-500!` sets a custom background color to a `btn` forcefully. This is a last resort solution and should be used sparingly
4. If a specific component or something similar to it doesn't exist in daisyUI, you can create your own component using Tailwind CSS utility
5. when using Tailwind CSS `flex` and `grid` for layout, it should be responsive using Tailwind CSS responsive utility prefixes.
6. Only allowed class names are existing daisyUI class names or Tailwind CSS utility classes.
7. Ideally, you won't need to write any custom CSS. Using daisyUI class names or Tailwind CSS utility classes is preferred.
8. suggested - if you need placeholder images, use https://picsum.photos/200/300 with the size you want
9. suggested - when designing , don't add a custom font unless it's necessary
10. don't add `bg-base-100 text-base-content` to body unless it's necessary
11. For design decisions, use Refactoring UI book best practices

daisyUI 5 class names are one of the following categories. these type names are only for reference and are not used in the actual code
- `component`: the required component class
- `part`: a child part of a component
- `style`: sets a specific style to component or part
- `behavior`: changes the behavior of component or part
- `color`: sets a specific color to component or part
- `size`: sets a specific size to component or part
- `placement`: sets a specific placement to component or part
- `direction`: sets a specific direction to component or part
- `modifier`: modifies the component or part in a specific way

## Config
daisyUI 5 config docs: https://daisyui.com/docs/config/
daisyUI without config:
```css
@plugin "daisyui";
```
daisyUI config with `light` theme only:
```css
@plugin "daisyui" {
  themes: light --default;
}
```
daisyUI with all the default configs:
```css
@plugin "daisyui" {
  themes: light --default, dark --prefersdark;
  root: ":root";
  include: ;
  exclude: ;
  prefix: ;
  logs: true;
}
```
An example config:
In below config, all the built-in themes are enabled while bumblebee is the default theme and synthwave is the prefersdark theme (default dark mode)
All the other themes are enabled and can be used by adding `data-theme="THEME_NAME"` to the `<html>` element
root scrollbar gutter is excluded. `daisy-` prefix is used for all daisyUI classes and console.log is disabled
```css
@plugin "daisyui" {
  themes: light, dark, cupcake, bumblebee --default, emerald, corporate, synthwave --prefersdark, retro, cyberpunk, valentine, halloween, garden, forest, aqua, lofi, pastel, fantasy, wireframe, black, luxury, dracula, cmyk, autumn, business, acid, lemonade, night, coffee, winter, dim, nord, sunset, caramellatte, abyss, silk;
  root: ":root";
  include: ;
  exclude: rootscrollgutter, checkbox;
  prefix: daisy-;
  logs: false;
}
```
## daisyUI 5 colors

### daisyUI color names
- `primary`: Primary brand color, The main color of your brand
- `primary-content`: Foreground content color to use on primary color
- `secondary`: Secondary brand color, The optional, secondary color of your brand
- `secondary-content`: Foreground content color to use on secondary color
- `accent`: Accent brand color, The optional, accent color of your brand
- `accent-content`: Foreground content color to use on accent color
- `neutral`: Neutral dark color, For not-saturated parts of UI
- `neutral-content`: Foreground content color to use on neutral color
- `base-100`:-100 Base surface color of page, used for blank backgrounds
- `base-200`:-200 Base color, darker shade, to create elevations
- `base-300`:-300 Base color, even more darker shade, to create elevations
- `base-content`: Foreground content color to use on base color
- `info`: Info color, For informative/helpful messages
- `info-content`: Foreground content color to use on info color
- `success`: Success color, For success/safe messages
- `success-content`: Foreground content color to use on success color
- `warning`: Warning color, For warning/caution messages
- `warning-content`: Foreground content color to use on warning color
- `error`: Error color, For error/danger/destructive messages
- `error-content`: Foreground content color to use on error color

### daisyUI color rules
1. daisyUI adds semantic color names to Tailwind CSS colors
2. daisyUI color names can be used in utility classes, like other Tailwind CSS color names. for example, `bg-primary` will use the primary color for the background
3. daisyUI color names include variables as value so they can change based the theme
4. There's no need to use `dark:` for daisyUI color names
5. Ideally only daisyUI color names should be used for colors so the colors can change automatically based on the theme
6. If a Tailwind CSS color name (like `red-500`) is used, it will be same red color on all themes
7. If a daisyUI color name (like `primary`) is used, it will change color based on the theme
8. Using Tailwind CSS color names for text colors should be avoided because Tailwind CSS color `text-gray-800` on `bg-base-100` would be unreadable on a dark theme - because on dark theme, `bg-base-100` is a dark color
9. `*-content` colors should have a good contrast compared to their associated colors
10. suggestion - when designing a page use `base-*` colors for majority of the page. use `primary` color for important elements

### daisyUI custom theme with custom colors
A CSS file with Tailwind CSS, daisyUI and a custom daisyUI theme looks like this:
```css
@import "tailwindcss";
@plugin "daisyui";
@plugin "daisyui/theme" {
  name: "mytheme";
  default: true; /* set as default */
  prefersdark: false; /* set as default dark mode (prefers-color-scheme:dark) */
  color-scheme: light; /* color of browser-provided UI */

  --color-base-100: oklch(98% 0.02 240);
  --color-base-200: oklch(95% 0.03 240);
  --color-base-300: oklch(92% 0.04 240);
  --color-base-content: oklch(20% 0.05 240);
  --color-primary: oklch(55% 0.3 240);
  --color-primary-content: oklch(98% 0.01 240);
  --color-secondary: oklch(70% 0.25 200);
  --color-secondary-content: oklch(98% 0.01 200);
  --color-accent: oklch(65% 0.25 160);
  --color-accent-content: oklch(98% 0.01 160);
  --color-neutral: oklch(50% 0.05 240);
  --color-neutral-content: oklch(98% 0.01 240);
  --color-info: oklch(70% 0.2 220);
  --color-info-content: oklch(98% 0.01 220);
  --color-success: oklch(65% 0.25 140);
  --color-success-content: oklch(98% 0.01 140);
  --color-warning: oklch(80% 0.25 80);
  --color-warning-content: oklch(20% 0.05 80);
  --color-error: oklch(65% 0.3 30);
  --color-error-content: oklch(98% 0.01 30);

  --radius-selector: 1rem; /* border radius of selectors (checkbox, toggle, badge) */
  --radius-field: 0.25rem; /* border radius of fields (button, input, select, tab) */
  --radius-box: 0.5rem; /* border radius of boxes (card, modal, alert) */

  --size-selector: 0.25rem; /* base size of selectors (checkbox, toggle, badge) */
  --size-field: 0.25rem; /* base size of fields (button, input, select, tab) */

  --border: 1px; /* border size */

  --depth: 1; /* only 0 or 1 – Adds a shadow and subtle 3D effect to components */
  --noise: 0; /* only 0 or 1 - Adds a subtle noise effect to components */
}
```
#### Rules
- All CSS variables above are required
- Colors can be OKLCH or hex or other formats

You can use https://daisyui.com/theme-generator/ to create your own theme

## daisyUI 5 components

### accordion
Accordion is used for showing and hiding content but only one item can stay open at a time

[accordion docs](https://daisyui.com/components/accordion/)

#### Class names
- component: `collapse`
- part: `collapse-title`, `collapse-content`
- modifier: `collapse-arrow`, `collapse-plus`, `collapse-open`, `collapse-close`

#### Syntax
```html
<div class="collapse {MODIFIER}">{CONTENT}</div>
```
where content is:
```html
<input type="radio" name="{name}" checked="{checked}" />
<div class="collapse-title">{title}</div>
<div class="collapse-content">{CONTENT}</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier class names
- Accordion uses radio inputs. All radio inputs with the same name work together and only one of them can be open at a time
- If you have more than one set of accordion items on a page, use different names for the radio inputs on each set
- Replace {name} with a unique name for the accordion group
- replace `{checked}` with `checked="checked"` if you want the accordion to be open by default

### alert
Alert informs users about important events

[alert docs](https://daisyui.com/components/alert/)

#### Class names
- component: `alert`
- style: `alert-outline`, `alert-dash`, `alert-soft`
- color: `alert-info`, `alert-success`, `alert-warning`, `alert-error`
- direction: `alert-vertical`, `alert-horizontal`

#### Syntax
```html
<div role="alert" class="alert {MODIFIER}">{CONTENT}</div>
```

#### Rules
- {MODIFIER} is optional and can have one of each style/color/direction class names
- Add `sm:alert-horizontal` for responsive layouts

### avatar
Avatars are used to show a thumbnail

[avatar docs](https://daisyui.com/components/avatar/)

#### Class names
- component: `avatar`, `avatar-group`
- modifier: `avatar-online`, `avatar-offline`, `avatar-placeholder`

#### Syntax
```html
<div class="avatar {MODIFIER}">
  <div>
    <img src="{image-url}" />
  </div>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier class names
- Use `avatar-group` for containing multiple avatars
- You can set custom sizes using `w-*` and `h-*`
- You can use mask classes such as `mask-squircle`, `mask-hexagon`, `mask-triangle`

### badge
Badges are used to inform the user of the status of specific data

[badge docs](https://daisyui.com/components/badge/)

#### Class names
- component: `badge`
- style: `badge-outline`, `badge-dash`, `badge-soft`, `badge-ghost`
- color: `badge-neutral`, `badge-primary`, `badge-secondary`, `badge-accent`, `badge-info`, `badge-success`, `badge-warning`, `badge-error`
- size: `badge-xs`, `badge-sm`, `badge-md`, `badge-lg`, `badge-xl`

#### Syntax
```html
<span class="badge {MODIFIER}">Badge</span>
```

#### Rules
- {MODIFIER} is optional and can have one of each style/color/size class names
- Can be used inside text or buttons
- To create an empty badge, just remove the text between the span tags

### breadcrumbs
Breadcrumbs helps users to navigate

[breadcrumbs docs](https://daisyui.com/components/breadcrumbs/)

#### Class names
- component: `breadcrumbs`

#### Syntax
```html
<div class="breadcrumbs">
  <ul><li><a>Link</a></li></ul>
</div>
```

#### Rules
- breadcrumbs only has one main class name
- Can contain icons inside the links
- If you set `max-width` or the list gets larger than the container it will scroll

### button
Buttons allow the user to take actions

[button docs](https://daisyui.com/components/button/)

#### Class names
- component: `btn`
- color: `btn-neutral`, `btn-primary`, `btn-secondary`, `btn-accent`, `btn-info`, `btn-success`, `btn-warning`, `btn-error`
- style: `btn-outline`, `btn-dash`, `btn-soft`, `btn-ghost`, `btn-link`
- behavior: `btn-active`, `btn-disabled`
- size: `btn-xs`, `btn-sm`, `btn-md`, `btn-lg`, `btn-xl`
- modifier: `btn-wide`, `btn-block`, `btn-square`, `btn-circle`

#### Syntax
```html
<button class="btn {MODIFIER}">Button</button>
```
#### Rules
- {MODIFIER} is optional and can have one of each color/style/behavior/size/modifier class names
- btn can be used on any html tags such as `<button>`, `<a>`, `<input>`
- btn can have an icon before or after the text
- set `tabindex="-1" role="button" aria-disabled="true"` if you want to disable the button using a class name

### calendar
Calendar includes styles for different calendar libraries

[calendar docs](https://daisyui.com/components/calendar/)

#### Class names
- component
  - `cally (for Cally web component)`
  - `pika-single (for the input field that opens Pikaday calendar)`
  - `react-day-picker (for the DayPicker component)`

#### Syntax
For Cally:
```html
<calendar-date class="cally">{CONTENT}</calendar-date>
```
For Pikaday:
```html
<input type="text" class="input pika-single">
```
For React Day Picker:
```html
<DayPicker className="react-day-picker">
```

#### Rules
- daisyUI supports Cally, Pikaday, React Day Picker

### card
Cards are used to group and display content

[card docs](https://daisyui.com/components/card/)

#### Class names
- component: `card`
- part: `card-title`, `card-body`, `card-actions`
- style: `card-border`, `card-dash`
- modifier: `card-side`, `image-full`
- size: `card-xs`, `card-sm`, `card-md`, `card-lg`, `card-xl`

#### Syntax
```html
<div class="card {MODIFIER}">
  <figure><img src="{image-url}" alt="{alt-text}" /></figure>
  <div class="card-body">
    <h2 class="card-title">{title}</h2>
    <p>{CONTENT}</p>
    <div class="card-actions">{actions}</div>
  </div>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier class names and one of the size class names
- `<figure>` and `<div class="card-body">` are optional
- can use `sm:card-horizontal` for responsive layouts
- If image is placed after `card-body`, the image will be placed at the bottom

### carousel
Carousel show images or content in a scrollable area

[carousel docs](https://daisyui.com/components/carousel/)

#### Class names
- component: `carousel`
- part: `carousel-item`
- modifier: `carousel-start`, `carousel-center`, `carousel-end`
- direction: `carousel-horizontal`, `carousel-vertical`

#### Syntax
```html
<div class="carousel {MODIFIER}">{CONTENT}</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/direction class names
- Content is a list of `carousel-item` divs: `<div class="carousel-item"></div>`
- To create a full-width carousel, add `w-full` to each carousel item

### chat
Chat bubbles are used to show one line of conversation and all its data, including the author image, author name, time, etc

[chat docs](https://daisyui.com/components/chat/)

#### Class names
- component: `chat`
- part: `chat-image`, `chat-header`, `chat-footer`, `chat-bubble`
- placement: `chat-start`, `chat-end`
- color: `chat-bubble-neutral`, `chat-bubble-primary`, `chat-bubble-secondary`, `chat-bubble-accent`, `chat-bubble-info`, `chat-bubble-success`, `chat-bubble-warning`, `chat-bubble-error`

#### Syntax
```html
<div class="chat {PLACEMENT}">
  <div class="chat-image"></div>
  <div class="chat-header"></div>
  <div class="chat-bubble {COLOR}">Message text</div>
  <div class="chat-footer"></div>
</div>
```

#### Rules
- {PLACEMENT} is required and must be either `chat-start` or `chat-end`
- {COLOR} is optional and can have one of the color class names
- To add an avatar, use `<div class="chat-image avatar">` and nest the avatar content inside

### checkbox
Checkboxes are used to select or deselect a value

[checkbox docs](https://daisyui.com/components/checkbox/)

#### Class names
- component: `checkbox`
- color: `checkbox-primary`, `checkbox-secondary`, `checkbox-accent`, `checkbox-neutral`, `checkbox-success`, `checkbox-warning`, `checkbox-info`, `checkbox-error`
- size: `checkbox-xs`, `checkbox-sm`, `checkbox-md`, `checkbox-lg`, `checkbox-xl`

#### Syntax
```html
<input type="checkbox" class="checkbox {MODIFIER}" />
```

#### Rules
- {MODIFIER} is optional and can have one of each color/size class names

### collapse
Collapse is used for showing and hiding content

[collapse docs](https://daisyui.com/components/collapse/)

#### Class names
- component: `collapse`
- part: `collapse-title`, `collapse-content`
- modifier: `collapse-arrow`, `collapse-plus`, `collapse-open`, `collapse-close`

#### Syntax
```html
<div tabindex="0" class="collapse {MODIFIER}">
  <div class="collapse-title">{title}</div>
  <div class="collapse-content">{CONTENT}</div>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier class names
- instead of `tabindex="0"`, you can use  `<input type="checkbox">` as a first child
- Can also be a details/summary tag

### countdown
Countdown gives you a transition effect when you change a number between 0 to 99

[countdown docs](https://daisyui.com/components/countdown/)

#### Class names
- component: `countdown`

#### Syntax
```html
<span class="countdown">
  <span style="--value:{number};">number</span>
</span>
```

#### Rules
- The `--value` CSS variable and text must be a number between 0 and 99
- you need to change the span text and the `--value` CSS variable using JS
- you need to add `aria-live="polite"` and `aria-label="{number}"` so screen readers can properly read changes

### diff
Diff component shows a side-by-side comparison of two items

[diff docs](https://daisyui.com/components/diff/)

#### Class names
- component: `diff`
- part: `diff-item-1`, `diff-item-2`, `diff-resizer`

#### Syntax
```html
<figure class="diff">
  <div class="diff-item-1">{item1}</div>
  <div class="diff-item-2">{item2}</div>
  <div class="diff-resizer"></div>
</figure>
```

#### Rules
- To maintain aspect ratio, add `aspect-16/9` or other aspect ratio classes to `<figure class="diff">` element

### divider
Divider will be used to separate content vertically or horizontally

[divider docs](https://daisyui.com/components/divider/)

#### Class names
- component: `divider`
- color: `divider-neutral`, `divider-primary`, `divider-secondary`, `divider-accent`, `divider-success`, `divider-warning`, `divider-info`, `divider-error`
- direction: `divider-vertical`, `divider-horizontal`
- placement: `divider-start`, `divider-end`

#### Syntax
```html
<div class="divider {MODIFIER}">{text}</div>
```

#### Rules
- {MODIFIER} is optional and can have one of each direction/color/placement class names
- Omit text for a blank divider

### dock
Dock (also know as Bottom navigation or Bottom bar) is a UI element that provides navigation options to the user. Dock sticks to the bottom of the screen

[dock docs](https://daisyui.com/components/dock/)

#### Class names
- component: `dock`
- part: `dock-label`
- modifier: `dock-active`
- size: `dock-xs`, `dock-sm`, `dock-md`, `dock-lg`, `dock-xl`

#### Syntax
```html
<div class="dock {MODIFIER}">{CONTENT}</div>
```
where content is a list of buttons:
```html
<button>
    <svg>{icon}</svg>
    <span class="dock-label">Text</span>
</button>
```

#### Rules
- {MODIFIER} is optional and can have one of the size class names
- To make a button active, add `dock-active` class to the button
- add `<meta name="viewport" content="viewport-fit=cover">` is required for responsivness of the dock in iOS

### drawer
Drawer is a grid layout that can show/hide a sidebar on the left or right side of the page

[drawer docs](https://daisyui.com/components/drawer/)

#### Class names
- component: `drawer`
- part: `drawer-toggle`, `drawer-content`, `drawer-side`, `drawer-overlay`
- placement: `drawer-end`
- modifier: `drawer-open`

#### Syntax
```html
<div class="drawer {MODIFIER}">
  <input id="my-drawer" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content">{CONTENT}</div>
  <div class="drawer-side">{SIDEBAR}</div>
</div>
```
where {CONTENT} can be navbar, site content, footer, etc
and {SIDEBAR} can be a menu like:
```html
<ul class="menu p-4 w-80 min-h-full bg-base-100 text-base-content">
  <li><a>Item 1</a></li>
  <li><a>Item 2</a></li>
</ul>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/placement class names
- `id` is required for the `drawer-toggle` input. change `my-drawer` to a unique id according to your needs
- `lg:drawer-open` can be used to make sidebar visible on larger screens
- `drawer-toggle` is a hidden checkbox. Use label with "for" attribute to toggle state
- if you want to open the drawer when a button is clicked, use `<label for="my-drawer" class="btn drawer-button">Open drawer</label>` where `my-drawer` is the id of the `drawer-toggle` input
- when using drawer, every page content must be inside `drawer-content` element. for example navbar, footer, etc should not be outside of `drawer`

### dropdown
Dropdown can open a menu or any other element when the button is clicked

[dropdown docs](https://daisyui.com/components/dropdown/)

#### Class names
- component: `dropdown`
- part: `dropdown-content`
- placement: `dropdown-start`, `dropdown-center`, `dropdown-end`, `dropdown-top`, `dropdown-bottom`, `dropdown-left`, `dropdown-right`
- modifier: `dropdown-hover`, `dropdown-open`

#### Syntax
Using details and summary
```html
<details class="dropdown">
  <summary>Button</summary>
  <ul class="dropdown-content">{CONTENT}</ul>
</details>
```

Using popover API
```html
<button popovertarget="{id}" style="anchor-name:--{anchor}">{button}</button>
<ul class="dropdown-content" popover id="{id}" style="position-anchor:--{anchor}">{CONTENT}</ul>
```

Using CSS focus
```html
<div class="dropdown">
  <div tabindex="0" role="button">Button</div>
  <ul tabindex="0" class="dropdown-content">{CONTENT}</ul>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/placement class names
- replace `{id}` and `{anchor}` with a unique name
- For CSS focus dropdowns, use `tabindex="0"` and `role="button"` on the button
- The content can be any HTML element (not just `<ul>`)

### fieldset
Fieldset is a container for grouping related form elements. It includes fieldset-legend as a title and label as a description

[fieldset docs](https://daisyui.com/components/fieldset/)

#### Class names
- Component: `fieldset`, `label`
- Parts: `fieldset-legend`

#### Syntax
```html
<fieldset class="fieldset">
  <legend class="fieldset-legend">{title}</legend>
  {CONTENT}
  <p class="label">{description}</p>
</fieldset>
```

#### Rules
- You can use any element as a direct child of fieldset to add form elements

### file-input
File Input is a an input field for uploading files

[file-input docs](https://daisyui.com/components/file-input/)

#### Class Names:
- Component: `file-input`
- Style: `file-input-ghost`
- Color: `file-input-neutral`, `file-input-primary`, `file-input-secondary`, `file-input-accent`, `file-input-info`, `file-input-success`, `file-input-warning`, `file-input-error`
- Size: `file-input-xs`, `file-input-sm`, `file-input-md`, `file-input-lg`, `file-input-xl`

#### Syntax
```html
<input type="file" class="file-input {MODIFIER}" />
```

#### Rules
- {MODIFIER} is optional and can have one of each style/color/size class names

### filter
Filter is a group of radio buttons. Choosing one of the options will hide the others and shows a reset button next to the chosen option

[filter docs](https://daisyui.com/components/filter/)

#### Class names
- component: `filter`
- part: `filter-reset`

#### Syntax
Using HTML form
```html
<form class="filter">
  <input class="btn btn-square" type="reset" value="×"/>
  <input class="btn" type="radio" name="{NAME}" aria-label="Tab 1 title"/>
  <input class="btn" type="radio" name="{NAME}" aria-label="Tab 2 title"/>
</form>
```
Without HTML form
```html
<div class="filter">
  <input class="btn filter-reset" type="radio" name="{NAME}" aria-label="×"/>
  <input class="btn" type="radio" name="{NAME}" aria-label="Tab 1 title"/>
  <input class="btn" type="radio" name="{NAME}" aria-label="Tab 2 title"/>
</div>
```

#### Rules
- replace `{NAME}` with proper value, according to the context of the filter
- Each set of radio inputs must have unique `name` attributes to avoid conflicts
- Use `<form>` tag when possible and only use `<div>` if you can't use a HTML form for some reason
- Use `filter-reset` class for the reset button

### footer
Footer can contain logo, copyright notice, and links to other pages

[footer docs](https://daisyui.com/components/footer/)

#### Class names
- component: `footer`
- part: `footer-title`
- placement: `footer-center`
- direction: `footer-horizontal`, `footer-vertical`

#### Syntax
```html
<footer class="footer {MODIFIER}">{CONTENT}</footer>
```
where content can contain several `<nav>` tags with `footer-title` and links inside

#### Rules
- {MODIFIER} is optional and can have one of each placement/direction class names
- try to use `sm:footer-horizontal` to make footer responsive
- suggestion - use `base-200` for background color

### hero
Hero is a component for displaying a large box or image with a title and description

[hero docs](https://daisyui.com/components/hero/)

#### Class names
- component: `hero`
- part: `hero-content`, `hero-overlay`

#### Syntax
```html
<div class="hero {MODIFIER}">{CONTENT}</div>
```

#### Rules
- {MODIFIER} is optional
- Use `hero-content` for the text content
- Use `hero-overlay` inside the hero to overlay the background image with a color
- Content can contain a figure

### indicator
Indicators are used to place an element on the corner of another element

[indicator docs](https://daisyui.com/components/indicator/)

#### Class names
- component: `indicator`
- part: `indicator-item`
- placement: `indicator-start`, `indicator-center`, `indicator-end`, `indicator-top`, `indicator-middle`, `indicator-bottom`

#### Syntax
```html
<div class="indicator">
  <span class="indicator-item">{indicator content}</span>
  <div>{main content}</div>
</div>
```

#### Rules
- Add all indicator elements (with `indicator-item` class) before the main content
- {placement} is optional and can have one of each horizonal/vertical class names. default is `indicator-end indicator-top`

### input
Text Input is a simple input field

[input docs](https://daisyui.com/components/input/)

#### Class names
- component: `input`
- style: `input-ghost`
- color: `input-neutral`, `input-primary`, `input-secondary`, `input-accent`, `input-info`, `input-success`, `input-warning`, `input-error`
- size: `input-xs`, `input-sm`, `input-md`, `input-lg`, `input-xl`

#### Syntax
```html
<input type="{type}" placeholder="Type here" class="input {MODIFIER}" />
```

#### Rules
- {MODIFIER} is optional and can have one of each style/color/size class names
- Can be used with any input field type (text, password, email, etc.)
- Use `input` class for the parent when you have more than one element inside input

### join
Join is a container for grouping multiple items, it can be used to group buttons, inputs, etc. Join applies border radius to the first and last item. Join can be used to create a horizontal or vertical list of items

[join docs](https://daisyui.com/components/join/)

#### Class names
- component: `join`, `join-item`
- direction: `join-vertical`, `join-horizontal`

#### Syntax
```html
<div class="join {MODIFIER}">{CONTENT}</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the direction class names
- Any direct child of the join element will get joined together
- Any element with `join-item` will be affected
- Use `lg:join-horizontal` for responsive layouts

### kbd
Kbd is used to display keyboard shortcuts

[kbd docs](https://daisyui.com/components/kbd/)

#### Class names
- component: `kbd`
- size: `kbd-xs`, `kbd-sm`, `kbd-md`, `kbd-lg`, `kbd-xl`

#### Syntax
```html
<kbd class="kbd {MODIFIER}">K</kbd>
```

#### Rules
- {MODIFIER} is optional and can have one of the size class names

### label
Label is used to provide a name or title for an input field. Label can be placed before or after the field

[label docs](https://daisyui.com/components/label/)

#### Class names
- component: `label`, `floating-label`

#### Syntax
For regular label:
```html
<label class="input">
  <span class="label">{label text}</span>
  <input type="text" placeholder="Type here" />
</label>
```
For floating label:
```html
<label class="floating-label">
  <input type="text" placeholder="Type here" class="input" />
  <span>{label text}</span>
</label>
```

#### Rules
- The `input` class is for styling the parent element which contains the input field and label, so the label does not have the 'input' class
- Use `floating-label` for the parent of an input field and a span that floats above the input field when the field is focused

### link
Link adds the missing underline style to links

[link docs](https://daisyui.com/components/link/)

#### Class names
- component: `link`
- style: `link-hover`
- color: `link-neutral`, `link-primary`, `link-secondary`, `link-accent`, `link-success`, `link-info`, `link-warning`, `link-error`

#### Syntax
```html
<a class="link {MODIFIER}">Click me</a>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier class names

### list
List is a vertical layout to display information in rows

[list docs](https://daisyui.com/components/list/)

#### Class Names:
- Component: `list`, `list-row`
- Modifier: `list-col-wrap`, `list-col-grow`

#### Syntax
```html
<ul class="list">
  <li class="list-row">{CONTENT}</li>
</ul>
```

#### Rules
- Use `list-row` for each item inside the list
- By default, the second child of the `list-row` will fill the remaining space. You can use `list-col-grow` on another child to make it fill the remaining space instead
- Use `list-col-wrap` to force an item to wrap to the next line

### loading
Loading shows an animation to indicate that something is loading

[loading docs](https://daisyui.com/components/loading/)

#### Class names
- component: `loading`
- style: `loading-spinner`, `loading-dots`, `loading-ring`, `loading-ball`, `loading-bars`, `loading-infinity`
- size: `loading-xs`, `loading-sm`, `loading-md`, `loading-lg`, `loading-xl`

#### Syntax
```html
<span class="loading {MODIFIER}"></span>
```

#### Rules
- {MODIFIER} is optional and can have one of the style/size class names

### mask
Mask crops the content of the element to common shapes

[mask docs](https://daisyui.com/components/mask/)

#### Class names
- component: `mask`
- style: `mask-squircle`, `mask-heart`, `mask-hexagon`, `mask-hexagon-2`, `mask-decagon`, `mask-pentagon`, `mask-diamond`, `mask-square`, `mask-circle`, `mask-star`, `mask-star-2`, `mask-triangle`, `mask-triangle-2`, `mask-triangle-3`, `mask-triangle-4`
- modifier: `mask-half-1`, `mask-half-2`

#### Syntax
```html
<img class="mask {MODIFIER}" src="{image-url}" />
```

#### Rules
- {MODIFIER} is required and can have one of the style/modifier class names
- You can change the shape of any element using `mask` class names
- You can set custom sizes using `w-*` and `h-*`

### menu
Menu is used to display a list of links vertically or horizontally

[menu docs](https://daisyui.com/components/menu/)

#### Class names
- component: `menu`
- part: `menu-title`, `menu-dropdown`, `menu-dropdown-toggle`
- modifier: `menu-disabled`, `menu-active`, `menu-focus`, `menu-dropdown-show`
- size: `menu-xs`, `menu-sm`, `menu-md`, `menu-lg`, `menu-xl`
- direction: `menu-vertical`, `menu-horizontal`

#### Syntax
Vertical menu:
```html
<ul class="menu">
  <li><button>Item</button></li>
</ul>
```
Horizontal menu:
```html
<ul class="menu menu-horizontal">
  <li><button>Item</button></li>
</ul>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/size/direction class names
- Use `lg:menu-horizontal` for responsive layouts
- Use `menu-title` for list item title
- Use `<details>` tag to make submenus collapsible
- Use `menu-dropdown` and `menu-dropdown-toggle` to toggle the dropdown using JS

### mockup-browser
Browser mockup shows a box that looks like a browser window

[mockup-browser docs](https://daisyui.com/components/mockup-browser/)

#### Class names
- component: `mockup-browser`
- part: `mockup-browser-toolbar`

#### Syntax
```html
<div class="mockup-browser">
  <div class="mockup-browser-toolbar">
    {toolbar content}
  </div>
  <div>{CONTENT}</div>
</div>
```

#### Rules
- For a default mockup, use just `mockup-browser` class name
- To set a URL in toolbar, add a div with `input` class

### mockup-code
Code mockup is used to show a block of code in a box that looks like a code editor

[mockup-code docs](https://daisyui.com/components/mockup-code/)

#### Class names
- component: `mockup-code`

#### Syntax
```html
<div class="mockup-code">
  <pre data-prefix="$"><code>npm i daisyui</code></pre>
</div>
```

#### Rules
- Use `<pre data-prefix="{prefix}">` to show a prefix before each line
- Use `<code>` tag to add code syntax highlighting (requires additional library)
- To highlight a line, add background/text color

### mockup-phone
Phone mockup shows a mockup of an iPhone

[mockup-phone docs](https://daisyui.com/components/mockup-phone/)

#### Class names
- component: `mockup-phone`
- part: `mockup-phone-camera`, `mockup-phone-display`

#### Syntax
```html
<div class="mockup-phone">
  <div class="mockup-phone-camera"></div>
  <div class="mockup-phone-display">{CONTENT}</div>
</div>
```

#### Rules
- Inside `mockup-phone-display` you can add anything

### mockup-window
Window mockup shows a box that looks like an operating system window

[mockup-window docs](https://daisyui.com/components/mockup-window/)

#### Class names
- component: `mockup-window`

#### Syntax
```html
<div class="mockup-window">
  <div>{CONTENT}</div>
</div>
```

### modal
Modal is used to show a dialog or a box when you click a button

[modal docs](https://daisyui.com/components/modal/)

#### Class names
- component: `modal`
- part: `modal-box`, `modal-action`, `modal-backdrop`, `modal-toggle`
- modifier: `modal-open`
- placement: `modal-top`, `modal-middle`, `modal-bottom`, `modal-start`, `modal-end`

#### Syntax
Using HTML dialog element
```html
<button onclick="my_modal.showModal()">Open modal</button>
<dialog id="my_modal" class="modal">
  <div class="modal-box">{CONTENT}</div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
</dialog>
```

Using checkbox (legacy)
```html
<label for="my-modal" class="btn">Open modal</label>
<input type="checkbox" id="my-modal" class="modal-toggle" />
<div class="modal">
  <div class="modal-box">{CONTENT}</div>
  <label class="modal-backdrop" for="my-modal">Close</label>
</div>
```

Using anchor links (legacy)
```html
<a href="#my-modal" class="btn">Open modal</a>
<div class="modal" id="my-modal">
  <div class="modal-box">{CONTENT}</div>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/placement class names
- Add `tabindex="0"` to make modal focusable
- Use unique IDs for each modal
- For HTML dialog element modals, add `<form method="dialog">` for closing the modal with submit

### navbar
Navbar is used to show a navigation bar on the top of the page

[navbar docs](https://daisyui.com/components/navbar/)

#### Class names
- component: `navbar`
- part: `navbar-start`, `navbar-center`, `navbar-end`

#### Syntax
```html
<div class="navbar">{CONTENT}</div>
```

#### Rules
- use `navbar-start`, `navbar-center`, `navbar-end` to position content horizontally
- put anything inside each section
- suggestion - use `base-200` for background color

### pagination
Pagination is a group of buttons

[pagination docs](https://daisyui.com/components/pagination/)

#### Class names
- component: `join`
- part: `join-item`
- direction: `join-vertical`, `join-horizontal`

#### Syntax
```html
<div class="join">{CONTENT}</div>
```

#### Rules
- Use `join-item` for each button or link inside the pagination
- Use `btn` class for styling pagination items

### progress
Progress bar can be used to show the progress of a task or to show the passing of time

[progress docs](https://daisyui.com/components/progress/)

#### Class names
- component: `progress`
- color: `progress-neutral`, `progress-primary`, `progress-secondary`, `progress-accent`, `progress-info`, `progress-success`, `progress-warning`, `progress-error`

#### Syntax
```html
<progress class="progress {MODIFIER}" value="50" max="100"></progress>
```

#### Rules
- {MODIFIER} is optional and can have one of the color class names
- You must specify value and max attributes

### radial-progress
Radial progress can be used to show the progress of a task or to show the passing of time

[radial-progress docs](https://daisyui.com/components/radial-progress/)

#### Class names
- component: `radial-progress`

#### Syntax
```html
<div class="radial-progress" style="--value:70;" aria-valuenow="70" role="progressbar">70%</div>
```

#### Rules
- The `--value` CSS variable and text must be a number between 0 and 100
- you need to add `aria-valuenow="{value}"`, `aria-valuenow={value}` so screen readers can properly read value and also show that its a progress element to them
- Use `div` instead of progress because browsers can't show text inside progress tag
- Use `--size` for setting size (default 5rem) and `--thickness` to set how thick the indicator is

### radio
Radio buttons allow the user to select one option

[radio docs](https://daisyui.com/components/radio/)

#### Class names
- component: `radio`
- color: `radio-neutral`, `radio-primary`, `radio-secondary`, `radio-accent`, `radio-success`, `radio-warning`, `radio-info`, `radio-error`
- size: `radio-xs`, `radio-sm`, `radio-md`, `radio-lg`, `radio-xl`

#### Syntax
```html
<input type="radio" name="{name}" class="radio {MODIFIER}" />
```

#### Rules
- {MODIFIER} is optional and can have one of the size/color class names
- Replace {name} with a unique name for the radio group
- Each set of radio inputs should have unique `name` attributes to avoid conflicts with other sets of radio inputs on the same page

### range
Range slider is used to select a value by sliding a handle

[range docs](https://daisyui.com/components/range/)

#### Class names
- component: `range`
- color: `range-neutral`, `range-primary`, `range-secondary`, `range-accent`, `range-success`, `range-warning`, `range-info`, `range-error`
- size: `range-xs`, `range-sm`, `range-md`, `range-lg`, `range-xl`

#### Syntax
```html
<input type="range" min="0" max="100" value="40" class="range {MODIFIER}" />
```

#### Rules
- {MODIFIER} is optional and can have one of each color/size class names
- You must specify `min` and `max` attributes

### rating
Rating is a set of radio buttons that allow the user to rate something

[rating docs](https://daisyui.com/components/rating/)

#### Class names
- component: `rating`
- modifier: `rating-half`, `rating-hidden`
- size: `rating-xs`, `rating-sm`, `rating-md`, `rating-lg`, `rating-xl`

#### Syntax
```html
<div class="rating {MODIFIER}">
  <input type="radio" name="rating-1" class="mask mask-star" />
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/size class names
- Each set of rating inputs should have unique `name` attributes to avoid conflicts with other ratings on the same page
- Add `rating-hidden` for the first radio to make it hidden so user can clear the rating

### select
Select is used to pick a value from a list of options

[select docs](https://daisyui.com/components/select/)

#### Class names
- component: `select`
- style: `select-ghost`
- color: `select-neutral`, `select-primary`, `select-secondary`, `select-accent`, `select-info`, `select-success`, `select-warning`, `select-error`
- size: `select-xs`, `select-sm`, `select-md`, `select-lg`, `select-xl`

#### Syntax
```html
<select class="select {MODIFIER}">
  <option>Option</option>
</select>
```

#### Rules
- {MODIFIER} is optional and can have one of each style/color/size class names

### skeleton
Skeleton is a component that can be used to show a loading state

[skeleton docs](https://daisyui.com/components/skeleton/)

#### Class names
- component: `skeleton`

#### Syntax
```html
<div class="skeleton"></div>
```

#### Rules
- Add `h-*` and `w-*` utility classes to set height and width

### stack
Stack visually puts elements on top of each other

[stack docs](https://daisyui.com/components/stack/)

#### Class Names:
- Component: `stack`
- Modifier: `stack-top`, `stack-bottom`, `stack-start`, `stack-end`

#### Syntax
```html
<div class="stack {MODIFIER}">{CONTENT}</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier class names
- You can use `w-*` and `h-*` classes to set the width and height of the stack, making all items the same size

### stat
Stat is used to show numbers and data in a block

[stat docs](https://daisyui.com/components/stat/)

#### Class names
- Component: `stats`
- Part: `stat`, `stat-title`, `stat-value`, `stat-desc`, `stat-figure`, `stat-actions`
- Direction: `stats-horizontal`, `stats-vertical`

#### Syntax
```html
<div class="stats {MODIFIER}">
  <div class="stat">{CONTENT}</div>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the direction class names
- It's horizontal by default but you can make it vertical with the `stats-vertical` class
- Content includes `stat-title`, `stat-value`, `stat-desc` inside a `stat`

### status
Status is a really small icon to visually show the current status of an element, like online, offline, error, etc

[status docs](https://daisyui.com/components/status/)

#### Class Names:
- Component: `status`
- Color: `status-neutral`, `status-primary`, `status-secondary`, `status-accent`, `status-info`, `status-success`, `status-warning`, `status-error`
- Size: `status-xs`, `status-sm`, `status-md`, `status-lg`, `status-xl`

#### Syntax
```html
<span class="status {MODIFIER}"></span>
```

#### Rules
- {MODIFIER} is optional and can have one of the color/size class names
- This component does not render anything visible

### steps
Steps can be used to show a list of steps in a process

[steps docs](https://daisyui.com/components/steps/)

#### Class Names:
- Component: `steps`
- Part: `step`, `step-icon`
- Color: `step-neutral`, `step-primary`, `step-secondary`, `step-accent`, `step-info`, `step-success`, `step-warning`, `step-error`
- Direction: `steps-vertical`, `steps-horizontal`

#### Syntax
```html
<ul class="steps {MODIFIER}">
  <li class="step">{step content}</li>
</ul>
```

#### Rules
- {MODIFIER} is optional and can have one of each direction/color class names
- To make a step active, add the `step-primary` class
- You can add an icon in each step using `step-icon` class
- To display data in `data-content` ,use `data-content="{value}"` at the `<li>`

### swap
Swap allows you to toggle the visibility of two elements using a checkbox or a class name

[swap docs](https://daisyui.com/components/swap/)

#### Class Names:
- Component: `swap`
- Part: `swap-on`, `swap-off`, `swap-indeterminate`
- Modifier: `swap-active`
- Style: `swap-rotate`, `swap-flip`

#### Syntax
Using checkbox
```html
<label class="swap {MODIFIER}">
  <input type="checkbox" />
  <div class="swap-on">{content when active}</div>
  <div class="swap-off">{content when inactive}</div>
</label>
```

Using class name
```html
<div class="swap {MODIFIER}">
  <div class="swap-on">{content when active}</div>
  <div class="swap-off">{content when inactive}</div>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/style class names
- Use only a hidden checkbox to control swap state or add/remove the `swap-active` class using JS to control state
- To show something when the checkbox is indeterminate, use `swap-indeterminate` class

### tab
Tabs can be used to show a list of links in a tabbed format

[tab docs](https://daisyui.com/components/tab/)

#### Class Names:
- Component: `tabs`
- Part: `tab`, `tab-content`
- Style: `tabs-box`, `tabs-border`, `tabs-lift`
- Modifier: `tab-active`, `tab-disabled`
- Placement: `tabs-top`, `tabs-bottom`

#### Syntax
Using buttons:
```html
<div role="tablist" class="tabs {MODIFIER}">
  <button role="tab" class="tab">Tab</button>
</div>
```

Using radio inputs:
```html
<div role="tablist" class="tabs tabs-box">
  <input type="radio" name="my_tabs" class="tab" aria-label="Tab" />
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the style/size class names
- Radio inputs are needed for tab content to work with tab click
- If tabs gets a background then every tab inside it becomes rounded from both top corners

### table
Table can be used to show a list of data in a table format

[table docs](https://daisyui.com/components/table/)

#### Class Names:
- Component: `table`
- Modifier: `table-zebra`, `table-pin-rows`, `table-pin-cols`
- Size: `table-xs`, `table-sm`, `table-md`, `table-lg`, `table-xl`

#### Syntax
```html
<div class="overflow-x-auto">
  <table class="table {MODIFIER}">
    <thead>
      <tr>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <th></th>
      </tr>
    </tbody>
  </table>
</div>
```

#### Rules
- {MODIFIER} is optional and can have one of each modifier/size class names
- The `overflow-x-auto` class is added to the wrapper div to make the table horizontally scrollable on smaller screens

### textarea
Textarea allows users to enter text in multiple lines

[textarea docs](https://daisyui.com/components/textarea/)

#### Class Names:
- Component: `textarea`
- Style: `textarea-ghost`
- Color: `textarea-neutral`, `textarea-primary`, `textarea-secondary`, `textarea-accent`, `textarea-info`, `textarea-success`, `textarea-warning`, `textarea-error`
- Size: `textarea-xs`, `textarea-sm`, `textarea-md`, `textarea-lg`, `textarea-xl`

#### Syntax
```html
<textarea class="textarea {MODIFIER}" placeholder="Bio"></textarea>
```

#### Rules
- {MODIFIER} is optional and can have one of each style/color/size class names

### theme-controller
If a checked checkbox input or a checked radio input with theme-controller class exists in the page, The page will have the same theme as that input's value

[theme-controller docs](https://daisyui.com/components/theme-controller/)

#### Class names
- component: `theme-controller`

#### Syntax
```html
<input type="checkbox" value="{theme-name}" class="theme-controller" />
```

#### Rules
- The value attribute of the input element should be a valid daisyUI theme name

### timeline
Timeline component shows a list of events in chronological order

[timeline docs](https://daisyui.com/components/timeline/)

#### Class Names:
- Component: `timeline`
- Part: `timeline-start`, `timeline-middle`, `timeline-end`
- Modifier: `timeline-snap-icon`, `timeline-box`, `timeline-compact`
- Direction: `timeline-vertical`, `timeline-horizontal`

#### Syntax
```html
<ul class="timeline {MODIFIER}">
  <li>
    <div class="timeline-start">{start}</div>
    <div class="timeline-middle">{icon}</div>
    <div class="timeline-end">{end}</div>
  </li>
</ul>
```

#### Rules
- {MODIFIER} is optional and can have one of the modifier/direction class names
- To make a vertical timeline, add the `timeline-vertical` class to the `ul` element or just do nothing (because its the default style.)
- Add `timeline-snap-icon` to snap the icon to the start instead of middle
- Add the `timeline-compact` class to force all items on one side

### toast
Toast is a wrapper to stack elements, positioned on the corner of page

[toast docs](https://daisyui.com/components/toast/)

#### Class Names:
- Component: `toast`
- Placement: `toast-start`, `toast-center`, `toast-end`, `toast-top`, `toast-middle`, `toast-bottom`

#### Syntax
```html
<div class="toast {MODIFIER}">{CONTENT}</div>
```

#### Rules
- {MODIFIER} is optional and can have one of the placement class names

### toggle
Toggle is a checkbox that is styled to look like a switch button

[toggle docs](https://daisyui.com/components/toggle/)

#### Class Names:
- Component: `toggle`
- Color: `toggle-primary`, `toggle-secondary`, `toggle-accent`, `toggle-neutral`, `toggle-success`, `toggle-warning`, `toggle-info`, `toggle-error`
- Size: `toggle-xs`, `toggle-sm`, `toggle-md`, `toggle-lg`, `toggle-xl`

#### Syntax
```html
<input type="checkbox" class="toggle {MODIFIER}" />
```

#### Rules
- {MODIFIER} is optional and can have one of each color/size class names

### validator
Validator class changes the color of form elements to error or success based on input's validation rules

[validator docs](https://daisyui.com/components/validator/)

#### Class names
- component: `validator`
- part: `validator-hint`

#### Syntax
```html
<input type="{type}" class="input validator" required />
<p class="validator-hint">Error message</p>
```

#### Rules
- Use with `input`, `select`, `textarea`