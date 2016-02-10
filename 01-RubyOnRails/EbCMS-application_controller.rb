module Eb
  # Eb application controller.
  class ApplicationController < ActionController::Base
    # Necessary actions for all application controller.
    before_action :detect_user
    before_action :set_locale
    before_action :get_engines
    before_action :getcontrollers
    before_action :check_frontend
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    protect_from_forgery with: :exception
    helper :all
    # Set default locale for translations.
    def default_url_options
      { locale: I18n.locale }
    end

    # Create list of views from engines collector.
    def check_frontend
      ar = Eb::Permission.getcontrollers true
      ar.each do |ara|
        if Eb::Frontend.css_exists?(ara)
          # Mylog::Mylog.debug
        end
      end
    end

    # TODO: Load helpers
    def load_helpers
      # hlp = []
      # ar = get_engines true
      Eb::ApplicationController.helper Eb::Posts::Engine.helpers
      # -- Temporary commented for future checking
      # ar.each do |engine|
      # ApplicationController.helper(engine.helpers)
      # helper engine.helpers
      # end
      # return hlp
    end

    # Set locale for whole site translation.
    def set_locale
      rxp = Regexp.new('[a-zA-Z]{2}')
      user_locale = cookies[:locale] || params[:locale]
      user_locale = user_locale.present? ? user_locale.scan(rxp) : 'en'
      # Check, is this locale available for using.
      #   Please note: this needed for disable invalid locale warning.
      available = I18n.available_locales.include?(user_locale[0].to_sym)
      I18n.locale = available ? user_locale[0] : 'en'
    end

    # Run authorization mechanism.
    def detect_user
      @session = Session.find_by(sesid: cookies[:scode])
      # TODO: Check agent and system to be sure that this is exactly this guy.
      #   Commented for checking more deeply authorization
      #   hash = request.env['HTTP_USER_AGENT']
      #   hash = Base64.encode64(hash)
      return false unless @session.present? # and @session.user_agent==hash
      @cur_user = User.find(@session.user_id)
    end

    # Check access control and grant or deny it
    #   Usage: If object presented - check is user_id is exact the
    #   same for grant author change
    #   Also this method modify @cur_user.author == true if allowed
    #   All groups are dynamically taken from database,
    #   but overall permissions are located in permissions.yml file
    #   You can generate permissions simply by run:
    #   rake permission:build
    def access_control(object = nil)
      if object.present? && @cur_user.present?
        author = author?
      end
      perm = Permission
      perm.getReq(params[:controller], params[:action], request.request_method)
      redirect t('redirect.denied') unless perm.grant?(user_perm, author)
    end

    # Check is author?
    def author?(object)
      is_user = object.class.name == @cur_user.class.name ? true : false
      author_id = is_user ? object.id : object.user_id
      author = author_id == @cur_user.id ? true : false
      author
    end

    # Get user permission
    def user_perm
      @cur_user.present? ? @cur_user.user_group.permission : 'z'
    end

    # Redirecting directive
    #   necessary to return for terminate any actions
    #   after redirecting to exclude double redirect error
    def redirect(notice = nil, where = nil)
      flash[:notice] = notice.blank? ? t('redirect.denied') : notice
      # If admin argument is equal admin - redirect going to admin panel or
      # if session[redirect_to] persist, redirect there
      redir = if where
                where == 'admin' ? eb.admin_path : where
              else
                :root
              end
      redir = session[:redirect_to] if session[:redirect_to].present?
      redirect_to redir
    end

    # Checking object for existance. Important for most of control actions
    def exist(obj)
      redirect t('redirect.not_found') if obj.nil?
    end

    # Can be deleted last object or not?
    def delete_last(obj)
      redirect t('redirect.delete_last') if obj.id == 1
    end

    # Get all eb CMS  engines connected to system
    def get_engines(engines = false)
      ebengines = []
      Rails::Engine.subclasses.each do |engine|
        ebengines << if engine.name.include?('Eb')
                       engines ? engine : engine.name
                     end
      end
      @engines = ebengines
      ebengines
    end

    # Get all eb engines connected to system
    def getcontrollers
      @controllers = Eb::Permission.getcontrollers
    end
  end
end
