require 'ronin/web/server'

require 'spec_helper'
require 'web/helpers/server'

describe Web::Server do
  before(:all) do
    @server = Web::Server.new do
      default do |env|
        response('This is default.')
      end

      bind('/test/bind.xml') do |env|
        response('<secret/>', :content_type => 'text/xml')
      end

      paths_like(/path_patterns\/secret\./) do |env|
        response('No secrets here.')
      end

      map('/test/map') do |env|
        response('mapped')
      end

      file('/test/file.txt',File.join(WEB_SERVER_ROOT,'test.txt'))

      mount('/test/mount/',WEB_SERVER_ROOT)
    end

    @virtual_host = Web::Server.new do
      bind('/test/virtual_host.xml') do |env|
        response('<virtual/>', :content_type => 'text/xml')
      end
    end

    @server.host('virtual.host.com') do
      bind('/test/virtual_host.xml') do |env|
        response('<virtual/>', :content_type => 'text/xml')
      end
    end

    @server.hosts_like(/^virtual[0-9]\./) do
      bind('/test/virtual_host_patterns.xml') do |env|
        response('<virtual-patterns/>', :content_type => 'text/xml')
      end
    end
  end

  it "should have a default host to listen on" do
    Web::Server.default_host.should_not be_nil
  end

  it "should have a default port to listen on" do
    Web::Server.default_port.should_not be_nil
  end

  it "should have built-in content types" do
    Web::Server.content_types.should_not be_empty
  end

  it "should map file extensions to content-types" do
    @server.content_type('html').should == 'text/html'
  end

  it "should have a default content-type for unknown files" do
    @server.content_type('lol').should == 'application/x-unknown-content-type'
  end

  it "should find the index file for a directory" do
    dir = WEB_SERVER_ROOT

    @server.index_of(dir).should == File.join(dir,'index.html')
  end

  it "should have a default response for un-matched paths" do
    @server.route_path('/test/default').body.should == ['This is default.']
  end

  it "should bind a path to a certain response" do
    @server.route_path('/test/bind.xml').body.should == ['<secret/>']
  end

  it "should match paths with patterns" do
    @server.route_path('/test/path_patterns/secret.pdf').body.should == ['No secrets here.']
  end

  it "should match paths to sub-directories" do
    @server.route_path('/test/map/impossible.html').body.should == ['mapped']
  end

  it "should return a response for a file" do
    @server.route_path('/test/file.txt').body.should == ["This is a test.\n"]
  end

  it "should return files from mounted directories" do
    @server.route_path('/test/mount/test.txt').body.should == ["This is a test.\n"]
  end

  it "should return the index file for a mounted directory" do
    @server.route_path('/test/mount/').body.should == ["Index of files.\n"]
  end

  it "should match virtual hosts" do
    url = 'http://virtual.host.com/test/virtual_host.xml'

    @server.route(url).body.should == ['<virtual/>']
  end

  it "should match virtual hosts with patterns" do
    url = 'http://virtual0.host.com/test/virtual_host_patterns.xml'

    @server.route(url).body.should == ['<virtual-patterns/>']
  end
end
