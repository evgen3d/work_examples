module Eb
class Upload < ActiveRecord::Base
	
	#------------------------------------------------
	# Necessary actions for uploads class
	#------------------------------------------------

	belongs_to :user
	has_many :uploads_preview, :dependent => :destroy
	before_save :savetodisk
	after_save :generate_previews
	before_destroy :remove_files
	
	# --  Necessary attributes
	attr_accessor :uploadedfile, :filename
	
	#------------------------------------------------
	# Methods
	#------------------------------------------------

	private
	def remove_files
		if File.exist?(Rails.root+"public/"+self.path)
			File.delete(Rails.root+"public/"+self.path)
		end
	end
	
	#------------------------------------------------
	# RAKE task - Build and rebuild previews for all uploaded images
	#------------------------------------------------

	public 

	def self.build_preview
		uploads = Upload.all
		previews = UploadsImgsResolution.all
		puts "Previews count "+previews.count.to_s
		generated = 0;	
		uploads.each do |upload|
			previews.each do |p|
				file = Rails.root.to_s + '/public'+upload.p(p.id)
				 if !File.exist?(file) or !File.file?(file)
				 	 puts "Some previews doesn't exists-"+upload.path
					generated = generated + upload.generate_previews(p.id)
				 end

			end
		end
		return generated
	end

	
	#------------------------------------------------
	# Generate previews action 
	#------------------------------------------------

	public
	def generate_previews(previewid = nil)
		filename = File.basename(self.path)
		pathWithPub = "public/#{self.path}"
		previews = Array.new
		
		# -- If previewID persists - use it, if no - use all from the database
		if previewid == nil 
			previews = UploadsImgsResolution.all
		else
			previews[0] = (UploadsImgsResolution.find(previewid))
		end

		dir3 = File.dirname(pathWithPub)
		generated = 0
		previews.each do |p|
			
			# -- Rmagics gem used here for resize the images
			img =  ::Magick::Image.read(pathWithPub).first
		        thumb = img.resize_to_fill(p.x, p.y)
		  	   
			# If you want to save this image use following
			pathTo = File.join(dir3,"thumbid_#{p.id}_"+filename)
			thumb.write(pathTo)
			pathTo.remove!("public/")
			
			# -- Add new generated preview to database
			preview = UploadsPreview.new(:upload_id => id, :uploads_imgs_resolution_id => p.id,:path => pathTo)
			preview.save
			generated=generated+1
		end
		return generated
	end

	#------------------------------------------------
	# Before save action: save to disk
	#------------------------------------------------

	  def savetodisk#(file)
		 file = uploadedfile
		 
		 # -- Use random name for save to disk
		 name =  preparename(file.original_filename)
		 type = file.content_type
		 year = Date.today.strftime("%Y")
		 month = Date.today.strftime("%m-%B")
		 day = Date.today.strftime("%d")
		 
		 # -- Base directory to save the file for public
		 directory = "public/data"
		 
		 # -- Generate folders for uploads for year-month-day
		 dir3 = File.dirname("#{directory}/#{year}/#{month}/#{day}/")
		 FileUtils.mkdir_p(dir3) unless File.directory?(dir3)

		 # create the file path
		 path = File.join(dir3, name)
		 # write the file
		 File.open(path, "wb") { |f| f.write(file.read) }
		 path.remove!("public/")
		 self.path = path
		 self.file_type = type
		 self.filename = name
	end
	  
	  #------------------------------------------------
	  # Prepare filename (should be rewritten for checking existance another file with the same name
	  #------------------------------------------------

	  def preparename(name)		
		  return SecureRandom.urlsafe_base64+File.extname(name)
	  end
	  
	  #------------------------------------------------
	  # Get image path with given preview ID
	  #------------------------------------------------

	public
	  def p(id)
		  if self.uploads_preview.exists?(:uploads_imgs_resolution_id => id)
			return	"/"+self.uploads_preview.find_by(:uploads_imgs_resolution_id => id).path
		  else
			  return ""

		  end
	  end
end
end
