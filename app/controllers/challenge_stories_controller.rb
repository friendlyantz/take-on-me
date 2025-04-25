class ChallengeStoriesController < ApplicationController
  before_action :set_challenge_story, only: %i[show edit update destroy]
  before_action :enforce_current_user, only: %i[new create edit update destroy]

  # GET /challenge_stories or /challenge_stories.json
  def index
    @challenge_stories = ChallengeStory.all.order(updated_at: :desc)
  end

  # GET /challenge_stories/1 or /challenge_stories/1.json
  def show
  end

  # GET /challenge_stories/new
  def new
    @challenge_story = ChallengeStory.new(
      start: Time.zone.today,
      finish: Time.zone.today + 28.days
    )
  end

  # GET /challenge_stories/1/edit
  def edit
  end

  # POST /challenge_stories or /challenge_stories.json
  def create
    @challenge_story = ChallengeStory.new(challenge_story_params)

    respond_to do |format|
      if @challenge_story.save
        format.html { redirect_to @challenge_story, notice: "Challenge story was successfully created." }
        format.json { render :show, status: :created, location: @challenge_story }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @challenge_story.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /challenge_stories/1 or /challenge_stories/1.json
  def update
    respond_to do |format|
      if @challenge_story.update(challenge_story_params)
        format.html { redirect_to @challenge_story, notice: "Challenge story was successfully updated." }
        format.json { render :show, status: :ok, location: @challenge_story }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @challenge_story.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /challenge_stories/1 or /challenge_stories/1.json
  def destroy
    @challenge_story.destroy!

    respond_to do |format|
      format.html { redirect_to challenge_stories_path, status: :see_other, notice: "Challenge story was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_challenge_story
    @challenge_story = ChallengeStory.find(params.expect(:id))
  end

  def challenge_story_params
    params.expect(challenge_story: [:title, :description, :start, :finish])
  end

  def enforce_current_user
    if current_user.blank?
      redirect_to new_session_path
    end
  end
end
