json.extract! challenge_story, :id, :title, :description, :start, :finish, :created_at, :updated_at
json.url challenge_story_url(challenge_story, format: :json)
