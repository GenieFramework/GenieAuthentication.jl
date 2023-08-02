module AddPictureToUsers

import SearchLight.Migration: add_columns, remove_columns
import SearchLight.Transactions: with_transaction

function up()
  with_transaction() do
    add_columns(:users, [
      :picture => :string
    ])
  end
end

function down()
  with_transaction() do
    remove_columns(:users, [
      :picture
    ])
  end
end

end
