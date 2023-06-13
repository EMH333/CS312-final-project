# install java from package
package 'openjdk-17-jdk-headless'

# add mcuser user
user 'mcuser' do
    comment 'Minecraft Server User'
    shell '/sbin/nologin'
end

# create minecraft directory
directory '/opt/minecraft' do
    owner 'mcuser'
    group 'mcuser'
    mode '0755'
end

# download minecraft server jar
remote_file '/opt/minecraft/server.jar' do
    source 'https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar'
    owner 'mcuser'
    group 'mcuser'
    mode '0744'
end

# accept eula
file '/opt/minecraft/eula.txt' do
    content 'eula=true'
    owner 'mcuser'
    group 'mcuser'
    mode '0644'
end

# create minecraft service
cookbook_file '/etc/systemd/system/minecraft.service' do
    source 'systemd.unit'
    owner 'root'
    group 'root'
    mode '0644'
end

# enable and start minecraft service
service 'minecraft' do
    action [:enable, :start]
end
