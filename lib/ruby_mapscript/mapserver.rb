# OGC compliant map server Rack Application
# OWS requests include WMS, WFS, WCS and SOS requests supported by MapServer

require "mapscript"
require 'fileutils'

module RubyMapscript

class Mapserver

  def initialize(mapfile, params = {})
    @wms = Mapscript::MapObj.new(mapfile)
	@server_params = params
	
	@server_params[:cache] ||= "#{Dir.pwd}/tmp/cache/tile"
	FileUtils.mkpath @server_params[:cache]
	
	p "-------------------------------------------------------"
	p @server_params
	p "-------------------------------------------------------"
	
  end

  def call(env)
    req = Mapscript::OWSRequest.new
    %w(REQUEST_METHOD QUERY_STRING HTTP_COOKIE).each do |var|
      ENV[var] = env[var]
    end
	rack_req = Rack::Request.new(env)
	
	#layer_digest = Digest::SHA1.hexdigest(rack_req.params['layers'])
	layer_digest = rack_req.params['layers']
	#digest = Digest::SHA1.hexdigest(rack_req.params['bbox'])+".png"	
	digest = rack_req.params['bbox'] +".png"	
	
	file_path = File.join(@server_params[:cache], layer_digest, digest[0])	
	
	#p "-------------------------------------------------------"
	#p "LAYER = #{rack_req.params['layers']} BBOX = #{rack_req.params['bbox']} ** #{layer_digest} - #{digest}"
	#p "-------------------------------------------------------"
	
	#if File.exists?(File.join(file_path, digest))
	#	[200, {'Content-Type' => rack_req.params['format']}, File(File.join(file_path, digest).read, 'rb')]
	#else
		FileUtils.mkpath file_path
		
		req.loadParams
		#Returns the number of name/value pairs collected.
		#Warning: most errors will result in a process exit!

		# redirect stdout & handle request
		Mapscript::msIO_installStdoutToBuffer()
		retval = @wms.OWSDispatch(req)
		#Returns MS_DONE (2) if there is no valid OWS request in the req object,
		# MS_SUCCESS (0) if an OWS request was successfully processed and
		# MS_FAILURE (1) if an OWS request was not successfully processed.
		content_type = Mapscript::msIO_stripStdoutBufferContentType()
		map_image = Mapscript::msIO_getStdoutBufferBytes()
		Mapscript::msIO_resetHandlers()
		
		#cache_file = File.new(File.join(file_path, digest), 'wb')
		#cache_file.write map_image
		
		[200, {'Content-Type' => content_type}, StringIO.new(map_image)]
	#end
  end
end

end