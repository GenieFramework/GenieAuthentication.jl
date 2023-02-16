module CreateTableApiTokens

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:apitokens) do
    [
      primary_key()
      column(:user_id, :int)
      column(:name, :string, limit = 100)    # username + date.now()
      column(:type, :string, limit = 100)    # ouath or jwt or other
      column(:token, :string, limit = 500)   # jwt tokens are usually 100-400 so kept that range
      column(:created_at, :date)
    ]
  end

  add_index(:apitokens, :user_id)
end

function down()
  drop_table(:apitokens)
end

end
