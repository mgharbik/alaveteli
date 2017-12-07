class Announcement < ActiveRecord::Base
  has_many :dismissals,
           class_name: 'AnnouncementDismissal',
           dependent: :destroy

  default_scope -> { order(created_at: :asc) }
  scope :for_user, -> (user) {
    where(
      'announcements.id NOT IN (SELECT announcement_id FROM ' \
      'announcement_dismissals WHERE user_id = :user_id)',
      user_id: user
    )
  }

  validates :title, :content, presence: true
end
