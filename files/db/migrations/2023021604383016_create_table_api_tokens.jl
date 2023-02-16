module CreateTableApiTokens

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:apitokens) do
    [
      primary_key()
      column(:user_id, :int)
      column(:name, :string, limit = 100)
      column(:type, :string, limit = 100)
      column(:token, :string, limit = 500)
    ]
  end

  add_index(:apitokens, :user_id)
end

function down()
  drop_table(:apitokens)
end

end
