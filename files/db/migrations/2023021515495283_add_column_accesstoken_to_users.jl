module AddColumnAccesstokenToUsers

import SearchLight.Migrations: add_columns, remove_columns,
add_index, remove_index

function up()
  add_columns(:users, [
    :accesstoken => :string
  ])
  add_index(:users, :accesstoken)
end
function down()
  remove_index(:todos, :accesstoken)
  remove_columns(:users, [
    :accesstoken
]) end
end
