require 'spec_helper'

RSpec.describe Announcement, type: :model do
  describe '.for_user' do
    let!(:user_1) { FactoryGirl.create(:user) }
    let!(:user_2) { FactoryGirl.create(:user) }
    let!(:announcement_all) do
      FactoryGirl.create(:announcement, title: 'All')
    end
    let!(:announcement_user_1) do
      FactoryGirl.create(:announcement, title: 'User 1', dismissed_by: user_2)
    end
    let!(:announcement_none) do
      FactoryGirl.create(:announcement, title: 'None',
                                        dismissed_by: [user_1, user_2])
    end

    it 'only returns undismissed announcements' do
      expect(Announcement.for_user(user_1)).to match_array(
        [announcement_all, announcement_user_1]
      )
      expect(Announcement.for_user(user_2)).to match_array(
        [announcement_all]
      )
    end
  end

  it 'requires a title' do
    announcement = FactoryGirl.build(:announcement, title: nil)
    expect(announcement).not_to be_valid
  end

  it 'requires content' do
    announcement = FactoryGirl.build(:announcement, content: nil)
    expect(announcement).not_to be_valid
  end
end
