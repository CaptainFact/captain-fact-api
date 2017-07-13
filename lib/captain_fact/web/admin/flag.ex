defmodule CaptainFact.Web.ExAdmin.Flag do
  use ExAdmin.Register
  alias CaptainFact.Web.Flag

  register_resource CaptainFact.Web.Flag do
    index do
      column :id
      column :type, [], fn f -> Flag.type_str(f.type) end
      column :reason, [], fn f -> Flag.reason_str(f.reason) end
      column :entity_id

      column :source_user, fields: [:username]
      column :target_user, fields: [:username]
    end

    show _ do
      attributes_table do
        row :id
        row :type, [], fn f -> Flag.type_str(f.type) end
        row :entity_id
        row :reason, [], fn f -> Flag.reason_str(f.reason) end

        row :inserted_at
        row :updated_at

        row :source_user, fields: [:username]
        row :target_user, fields: [:username]
      end
    end
  end
end
