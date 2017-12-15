class AdminAnnouncementsController < AdminController
  before_action :set_announcement, only: %i[edit update destroy]

  def index
    @announcements = Announcement.all
  end

  def new
    @announcement = Announcement.new
  end

  def create
    @announcement = Announcement.new(announcement_params)
    if @announcement.save
      notice = 'Announcement successfully created.'
      redirect_to admin_announcements_path, notice: notice
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @announcement.update_attributes(announcement_params)
      notice = 'Announcement successfully updated.'
      redirect_to admin_announcements_path, notice: notice
    else
      render :edit
    end
  end

  def destroy
    @announcement.destroy
    notice = 'Announcement successfully destroyed'
    redirect_to admin_announcements_path, notice: notice
  end

  private

  def announcement_params
    if params[:announcement]
      params.require(:announcement).permit(:title, :content)
    else
      {}
    end
  end

  def set_announcement
    @announcement = Announcement.find(params[:id])
  end
end
