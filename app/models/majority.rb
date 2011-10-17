#  Copyright (c) 2010-2011, Nathan Sobo and Max Brunsfeld.  This file is
#  licensed under the Affero General Public License version 3 or later.  See
#  the COPYRIGHT file.

class Majority < Prequel::Record
  column :id, :integer
  column :question_id, :integer
  column :winner_id, :integer
  column :loser_id, :integer
  column :pro_count, :integer, :default => 0
  column :con_count, :integer, :default => 0
  column :winner_created_at, :datetime

  belongs_to :question
  belongs_to :winner, :class_name => "Answer"
  belongs_to :loser, :class_name => "Answer"

  def before_create
    self.winner_created_at = winner.created_at
  end
end