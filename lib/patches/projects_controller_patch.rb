require_dependency 'projects_controller'

module  Patches
  module ProjectsControllerPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain  :index, :filter_project
      end
    end
  end
  module ClassMethods
  end

  module InstanceMethods
    def index_with_filter_project
      @plugin = Redmine::Plugin.find("redmine_enhanced_projects_list")
      @partial = @plugin.settings[:partial]


      unless @plugin.configurable?
        render_404
        return
      end


      respond_to do |format|
        format.html {
          @settings = Setting.send "plugin_redmine_enhanced_projects_list"
          scope = Project
          unless params[:closed]
            scope = scope.active
          end
          @projects = scope.visible.where("parent_id is null").order('lft').all
        }
        format.api  {
          @offset, @limit = api_offset_and_limit
          @project_count = Project.visible.count
          @projects = Project.visible.offset(@offset).limit(@limit).order('lft').all
        }
        format.atom {
          projects = Project.visible.order('created_on DESC').limit(Setting.feeds_limit.to_i).all
          render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
        }
        format.js{
          scope = Project
          unless params[:closed]
            scope = scope.active
          end

          if params[:project_search]
            @projects = scope.visible.where("name like ? or identifier like ? ","%#{params[:project_search]}%","%#{params[:project_search]}%").order('lft')
          else
            Setting.send "plugin_redmine_enhanced_projects_list=", params[:settings]
            @projects = scope.visible.where("parent_id is null").order('lft').all
          end

          @settings = Setting.send "plugin_redmine_enhanced_projects_list"
        }
      end
    end
  end
end


