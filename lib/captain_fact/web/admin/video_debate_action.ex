defmodule CaptainFact.Web.ExAdmin.VideoDebateAction do
  use ExAdmin.Register

  register_resource CaptainFact.Web.VideoDebateAction do
    index do
      column :id
      column :user, fields: [:username]
      column :video
      column :entity
      column :entity_id
      column :type
    end
  end
end
