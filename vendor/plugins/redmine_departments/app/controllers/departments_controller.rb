class DepartmentsController < ApplicationController
  unloadable

  # helper���������ÿ�����ʹ�÷�Ĭ�ϵİ���ģ��
  helper :departments
  include DepartmentsHelper
  helper :sort
  include SortHelper
  helper :issues

  def index
    sort_init 'name', 'asc'
  # %w��������
    sort_update %w(name manager_id description parent_id status created_on updated_on)
  # ��ѯ��Department�����м�¼����sort_clause��������
    @departments = Department.find :all, :order => sort_clause
  # �ж��Ƿ��첽��������ǾͲ���layout
    render :layout => !request.xhr?
  end

  def show
  # ͨ��idȥ��ѯDepartment��¼
  # params����һ����ϣ�ṹ�Ķ������ڷ�װ���ݵ�Action�����Ĳ�����������params[:id]����params['id']ȡֵ���������Ϊ��������
    @department = Department.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @department}
      # format.json { render :json => @department.to_json(:include => "") }
    end
  # rescue���쳣���൱�� Java��Exception
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new
    @department = Department.new(params[:department])
    if request.post? and @department.save
      # change lft rgt
      @department.set_allowed_parent!(params[:department]['parent_id']) if params[:department].has_key?('parent_id')
  # flash[:notice] ��ʾ����Ϣ
      flash[:notice] = l(:notice_successful_create)
  # redirect_to ת�����
      redirect_to(params[:continue] ? {:controller => 'departments', :action => 'new'} :
                      {:controller => 'departments', :action => 'edit', :id => @department})
    end
  end

  def edit
    @department = Department.find(params[:id])

    if request.post? and @department.update_attributes(params[:department])
      # change lft rgt
      @department.set_allowed_parent!(params[:department]['parent_id']) if params[:department].has_key?('parent_id')

      flash[:notice] = l(:notice_successful_update)
  # redirect_to :back,������һ�η��ʵ�ҳ��
      redirect_to :back
    end

  rescue ::ActionController::RedirectBackError
    redirect_to :controller => 'departments', :action => 'edit', :id => @department
  end

  def destroy
    @department = Department.find(params[:id])
    if request.get?
      # display confirmation view
    else
      if @department.destroy
        flash[:notice] = l(:notice_successful_delete)
        redirect_to :controller => 'departments', :action => 'index'
      end
    end
  end

  def orgchart
    # @departments = Department.all
    @departments = Department.visible.find(:all, :order => 'lft')
  end

  def select
    @departments = Department.all
  end

  def json
    @departments = Department.all
    respond_to do |format|
      format.json  { render :json => @departments }
    end
  end

  def add_users
    @department = Department.find(params[:id])
    users = User.find_all_by_id(params[:user_ids])
    users.each do |user|
      du = DepartmentUser.new
      du.department_id = @department.id
      du.user_id =user.id
      du.save
    end
  # respond_to
    respond_to do |format|
      format.html { redirect_to :controller => 'departments', :action => 'show', :id => @department, :tab => 'users' }
      format.js {
        render(:update) {|page|
          page.replace_html "tab-content-users", :partial => 'departments/users'
          users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
        }
      }
    end
  end

  def remove_user
    @department = Department.find(params[:id])
    @du = DepartmentUser.find(params[:user_id])
    @du.destroy if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'departments', :action => 'show', :id => @department, :tab => 'users' }
      format.js { render(:update) {|page| page.replace_html "tab-content-users", :partial => 'departments/users'} }
    end
  end

  def autocomplete_for_user
    @department = Department.find(params[:id])
    @users = User.active.like(params[:q]).find(:all, :limit => 100)
    render :layout => false
  end

  def member_worktime
    @user = User.current

    @time_entries = TimeEntry.find(:all, :conditions => [ "user_id = ?", @user.id], :order => "spent_on DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ftp_accounts }
    end
  end

  # Validates parent_id param according to user's permissions
  # TODO: move it to Department model in a validation that depends on User.current
  def validate_parent_id
    return true if User.current.admin?
  # params[:department][:parent_id]��˼��{:department=>{:parent_id=>"xxx"}}
  # a&&b����������ͷ���b
    parent_id = params[:department] && params[:department][:parent_id]
    if parent_id || @department.new_record?
      parent = parent_id.blank? ? nil : Department.find_by_id(parent_id.to_i)
      unless @department.allowed_parents.include?(parent)
        @department.errors.add :parent_id, :invalid
        return false
      end
    end
    true
  end
end
