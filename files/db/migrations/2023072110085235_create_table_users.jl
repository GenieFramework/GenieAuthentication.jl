module CreateTableUsers

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
  create_table(:users) do
    [
      primary_key()
      column(:username, :string, limit = 100)
      column(:password, :string, limit = 100)
      column(:name, :string, limit = 100)
      column(:email, :string, limit = 100)
      column(:token, :string, limit = 100)
    ]
  end

  add_index(:users, :username)
  add_index(:users, :email, unique = true)
  add_index(:users, :token, unique = true)
end

function down()
  drop_table(:users)
end

end