require 'graph'
require 'path'
require 'trema'

# L2 routing path manager
class PathManager < Trema::Controller
  def start
    @graph = Graph.new
    logger.info 'Path Manager started.'
  end

  # This method smells of :reek:FeatureEnvy but ignores them
  def packet_in(_dpid, packet_in)
    puts "packet_in"
    path = maybe_create_shortest_path(packet_in)
    ports = path ? [path.out_port] : @graph.external_ports
    p @graph
    ports.each do |each|
#      p each
      send_packet_out(each.dpid,
                      raw_data: packet_in.raw_data,
                      actions: SendOutPort.new(each.number))
    end
  end

  def add_port(port, _topology)
    @graph.add_link port.dpid, port
  end

  def delete_port(port, _topology)
    @graph.delete_node port
  end

  # TODO: update all paths
  def add_link(port_a, port_b, _topology)
    @graph.add_link port_a, port_b
  end

  def delete_link(port_a, port_b, _topology)
    @graph.delete_link port_a, port_b
    Path.find { |each| each.link?(port_a, port_b) }.each(&:destroy)
  end

  def add_host(mac_address, port, _topology)
    @graph.add_link mac_address, port
  end

  private

  # This method smells of :reek:FeatureEnvy but ignores them
  def maybe_create_shortest_path(packet_in)
    puts "create shortest path"
    unless packet_in.data.is_a? Parser::IPv4Packet then return end
    puts packet_in.destination_ip_address.to_a
    destination_ip = packet_in.destination_ip_address.to_a
    source_ip = packet_in.source_ip_address.to_a
    if destination_ip[3] > 100 then
      #dest = Mac.new ("54:53:ed:1c:36:82")
      dest = "54:53:ed:1c:36:82"
      puts "dest rewrited!!"
    else
      dest = packet_in.destination_mac
    end
    if source_ip[3] > 100 then
      #source = Mac.new ("54:53:ed:1c:36:82")
      source = "54:53:ed:1c:36:82"
      puts "source rewrited!!"
    else
      source = packet_in.source_mac
    end
    shortest_path =
      @graph.dijkstra(source, dest)
    return unless shortest_path
    if dest != packet_in.destination_mac then
      #shortest_path.push(packet_in.destination_mac)
    end
    puts shortest_path
    Path.create shortest_path, packet_in
  end
end
