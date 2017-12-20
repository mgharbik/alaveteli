class Announcement < ActiveRecord::Base
  belongs_to :user,
             inverse_of: :announcements
  has_many :dismissals,
           class_name: 'AnnouncementDismissal',
           inverse_of: :announcement,
           dependent: :destroy

  translates :title, :content
  include Translatable

  default_scope -> { order(created_at: :asc) }
  scope :for_user, -> (user) {
    return unless user

    # has the user dismissed the announcement
    where(
      'announcements.id NOT IN (SELECT announcement_id FROM ' \
      'announcement_dismissals WHERE user_id = :user_id)',
      user_id: user
    )
  }

  validates :content, :user, presence: true
end
