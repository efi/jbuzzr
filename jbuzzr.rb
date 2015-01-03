# encoding: utf-8
Encoding.default_external = 'utf-8'
Encoding.default_internal = 'utf-8'
require 'hidapi-rw-1.1.jar'

module JBuzzr

class Lights
  attr_reader :status
  def initialize controller
    @status=(0...4).map{false}
    @controller=controller
  end
  def update a,b,c,d
    old_status=@status.clone
    @status[0]=!!a unless a.nil?
    @status[1]=!!b unless b.nil?
    @status[2]=!!c unless c.nil?
    @status[3]=!!d unless d.nil?
    if old_status!=@status
      out=Java::byte[6].new
      [false,false,@status].flatten.each_with_index{|b,i| out[i]-=1 if b}
      @controller.write out
    end
    @status
  end
end

class Status
  def initialize controller
    @status=(0...4).map{(0...4).map{false}}
    @controller=controller
    read_loop
  end
  def listeners
    @listeners||=[]
  end
  private
  def read_loop
    Thread.new{
      buffer=Java::byte[6].new
      while true
        begin
        old_status=@status.clone
        @controller.read buffer
        @status=buffer.to_a.pack("C*").unpack("b*").first[16...36].chars.to_a.each_slice(5).map{|c|c.map{|b|b=="1"}}
        status_change_events(old_status, @status) if old_status!=@status
        rescue Exception => ex
          p ex
          return
        end
      end
    }
  end
  def status_change_events before, after
    events=[]
    (0..3).each do |i|
      b=before[i]; a=after[i]
      events<<{controller:i+1, button: :buzzer, action: :pressed}  if !b[0] && a[0]
      events<<{controller:i+1, button: :buzzer, action: :released} if b[0] && !a[0]
      events<<{controller:i+1, button: :yellow, action: :pressed}  if !b[1] && a[1]
      events<<{controller:i+1, button: :yellow, action: :released} if b[1] && !a[1]
      events<<{controller:i+1, button: :green,  action: :pressed}  if !b[2] && a[2]
      events<<{controller:i+1, button: :green,  action: :released} if b[2] && !a[2]
      events<<{controller:i+1, button: :orange, action: :pressed}  if !b[3] && a[3]
      events<<{controller:i+1, button: :orange, action: :released} if b[3] && !a[3]
      events<<{controller:i+1, button: :blue,   action: :pressed}  if !b[4] && a[4]
      events<<{controller:i+1, button: :blue,   action: :released} if b[4] && !a[4]
    end
    events.each do |e|
      e[:device_identity]=@controller.hash^e[:controller].to_s.to_sym.hash
      e[:timestamp]=Time.now.to_f
      @listeners.each{|l| l.call e}
    end
  end
end

class Device
  def initialize usb_device
    @usb_device=usb_device
  end
  def usb_device
    @usb_device
  end
  def lights
    @lights||=Lights.new @usb_device
  end
  def status
    @status||=Status.new @usb_device
  end
end

com.codeminders.hidapi.ClassPathLibraryLoader.loadNativeHIDLibrary
def self.devices
  @@usb_devices ||= {}
  @@usb_devices = Hash[@@usb_devices.select{|path,device| device.usb_device.get_product_string=="Buzz"}]
  usb_manager = com.codeminders.hidapi.HIDManager.get_instance
  usb_manager.list_devices.select{|d|d.product_string=="Buzz"}.each do |device_info|
    device_path = device_info.path
    next if @@usb_devices[device_path]
    device = device_info.open
    @@usb_devices [device_path] = Device.new(device) if device
  end
  @@usb_devices
end

end # module JBuzzr

at_exit do JBuzzr.devices.each do |d| begin
  d.usb_device.close
  com.codeminders.hidapi.HIDManager.instance.release
rescue ; end ; end ; end
