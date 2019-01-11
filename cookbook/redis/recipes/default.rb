package "epel-release"

package "redis"

service "redis" do
	action [:enable, :start]
end