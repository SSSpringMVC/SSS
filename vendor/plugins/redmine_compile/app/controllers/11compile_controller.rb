class CompileController < ApplicationController
  unloadable
  
  before_filter :find_project, :authorize
  
  def index
    @identifier = Project.find(@project)   
    project_id = @identifier.id
    @compile = Compile.find(:all,:conditions=>"project_id = '#{project_id}'")
  end
  
  def new
    if request.post?
      @produce = Compile.find_by_produce(params[:new])
      if @produce 
           flash[:notice] = "产品已经被创建过！！！"
           redirect_to :controller => 'compile', :action => 'index', :id => @project
      else
        @identifier = Project.find(@project)   
        project_id = @identifier.id
        @compile = Compile.new(:project_id => project_id,:produce => params[:new])
        if @compile.save
          flash[:notice] = "创建成功！"
          redirect_to :controller => 'compile', :action => 'index', :id => @project
        end
      end
    end
  end
  
  def destroy
    @compile = Compile.find_by_produce(params[:produce])
    @compile.destroy
    flash[:notice] = "删除成功！"
    redirect_to :controller => 'compile', :action => 'index', :id => @project
  end
  
  
  def docompile
    t = Time.new
    date = t.strftime("%Y%m%d")
    
    puts date    
    ramdom = newpass(10)
    puts ramdom
    
    @user = User.find(User.current)
    puts @user.login
    
    a = "/opt/ioa/bbb/svn/"
    if File.directory? a
    else
      Dir.mkdir(a)
    end
    
    @identifier = Project.find(@project)   
    b = a + @identifier.identifier
    puts b
    if File.directory? b
    else
      Dir.mkdir(b)
    end
    
    @propuct = params[:produce]
    c = b + "/" + @propuct 
    if File.directory? c
    else
      Dir.mkdir(c)
    end
     
    d = date + "-" + ramdom + "-" + @user.login 
    @e = c + "/" + d
    puts d
    puts @e
    
    if File.directory? @e
    else
      Dir.mkdir(@e)
    end
    
    f = a + "redmine/"
    if File.directory? f
    else
      Dir.mkdir(f)
    end    
    puts f
    
     g = f + ramdom + "svn.redmine"
     h = g + ".tmp"
     puts g
     fd = File.new(h, "w+") 
     
     i = "src=" + @identifier.identifier
     j = "product=" + @propuct 
     k = "PathOutput=" + @e
     l = "user=tmp\n"
     m = "tag=tag\n" 
     n = "name=" + @identifier.name
     
     @o = Repository.find_by_project_id(@identifier.id)
     puts @o
     p = "svnpath=" + @o.url
     fd.puts i
     fd.puts j
     fd.puts k
     fd.puts l
     fd.puts m
     fd.puts n 
     fd.puts p 
     fd.close
     
     File.rename( h, g )
     flash[:notice] = "正在进行编译！"
    
  end
  
  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:id]) 
  end
  
  def newpass(len)
    newpass = ""
    1.upto(len){ |i| newpass << rand(10).to_s}
    return newpass
  end
end
