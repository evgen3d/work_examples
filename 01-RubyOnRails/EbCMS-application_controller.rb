module Eb
  class ApplicationController < ActionController::Base
	  
	#------------------------------------------------
	# Necessary actions for all application controller
	#------------------------------------------------

	before_action :detect_user
	before_action :set_locale
	before_action :get_engines
	before_action :get_controllers
	before_action :check_frontend

	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception
	helper :all
	
	# -- Set default locale for translations
	def default_url_options(options={})
	    { locale: I18n.locale }
      	end
	
#------------------------------------------------
# Create list of views from engines collector
#------------------------------------------------

	def check_frontend 
		Mylog::Mylog.debug b.get
	end
#---------------------------------------------------------
# Load helpers 
#---------------------------------------------------------
	def load_helpers
		hlp=Array.new
		ar=get_engines true
		Eb::ApplicationController.helper Eb::Posts::Engine.helpers
		
		# -- Temporary commented for future checking
		#ar.each do |engine|

		#	ApplicationController.helper(engine.helpers)
			#helper engine.helpers

		#	end
	#return hlp
	end
#---------------------------------------------------------
# Set locale for whole site translation
#---------------------------------------------------------
 
  
	  def set_locale
		I18n.locale = params[:locale] || "en"
	  end

#---------------------------------------------------------
# Run authorization mechanism
#---------------------------------------------------------
	  private

	  def detect_user

			@session = Session.find_by(sesid:cookies[:scode])
			
			# Check user agent and system to be sure that this is exactly this guy
			hash=request.env['HTTP_USER_AGENT'] 
			hash= Base64.encode64(hash)
			if @session.present? # --  commented for checking more deeply authorization: and @session.user_agent==hash

				@cur_user = User.find(@session.user_id)

			end

	  end

#---------------------------------------------------------
# => Check access control and grant or deny it
#
# => Usage: If object presented - check is user_id is exact the same for grant author change
# => Also this method modify @cur_user.author == true if allowed
# All groups are dynamically taken from database, but overall permissions are located in permissions.yml file
# You can generate permissions simply by run:
# rake permission:build
#---------------------------------------------------------

	  private

	  def access_control(object = nil)

	      author = false

	      if !object.nil? && !@cur_user.nil?

		if object.class.name == @cur_user.class.name

		    author_id = object.id

		else

		    author_id = object.user_id

		end

		if author_id == @cur_user.id

		  author = true


		else
		  author = false

		end

	      end

	      permission = Permission
	      perm = permission.getReq(params[:controller], params[:action], request.request_method)

	      if @cur_user.present?

		user_perm = @cur_user.user_group.permission

	      else

		# -- Z - permission is default for non-logged user
		user_perm="z"  

	      end

	      if !permission.grant?(user_perm, author)
		redirect t('redirect.denied') 
	      end

	  end

#---------------------------------------------------------
# Redirecting directive
# necessary to return for terminate any actions after redirecting to exclude double redirect error
#---------------------------------------------------------

	  def redirect(notice = nil, where = nil)

	    if notice.blank?
	      flash[:notice] = t("redirect.denied")
	    else
	      flash[:notice] = notice
	    end

#-----------------------------------------
# If admin argument is equal admin - redirect going to admin panel or 
#----------------------------------------
    
	      if where
		      if where=='admin'
			      redirect_to :controller=>"eb/admin"
		      else
				redirect_to where
		      end
	     else
		redirect_to :root
	     end


	  end

#---------------------------------------------------------
# exist?
# Checking object for existing. Important for most of control actions
#---------------------------------------------------------
	  def exist(obj)

	    if obj.nil?

	      redirect t("redirect.not_found")

	    end

	  end

#---------------------------------------------------------
# Can be deleted last object or not?
#---------------------------------------------------------
  
	  def deleteLast(obj)

	    if obj.id == 1

	      redirect t("redirect.delete_last") 

	    end
	    
	  end

#---------------------------------------------------------
# Get all eb CMS  engines connected to system
#---------------------------------------------------------
  
	 def get_engines(engines=false)

		engines = Array.new
		
		# Getting engines rails in Eb namespace 
		Rails::Engine.subclasses.each do |engine|
			if engine.name.include?("Eb")
				if engines
					engines << engine
				else
					engines << engine.name
				end
			end
		end
		@engines = engines
		return engines

	 end

#---------------------------------------------------------
# Get all eb engines connected to system
#---------------------------------------------------------

	 def get_controllers
		 @controllers=Eb::Permission.getcontrollers
	 end

 end
end

