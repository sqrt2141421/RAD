local pr=love.filesystem.getSourceBaseDirectory()
package.path=package.path..";"..pr.."/lib/?.lua"
local ch_s,err_s=loadfile(pr.."/lib/enet_1.lua")
local ch_d,err_d=loadfile(pr.."/server/data.lua")
if not (ch_s and ch_d) then error("ERROR LOAD MODULE:\n"..(err_s or"").."\n"..(err_d or"")) end
local enet=require("enet")
local s=ch_s(enet)
local d=ch_d()
function love.load()
    adress=d.adress_servers[1]
    flag_connect=true
    time_reconnect=d.time_reconnect
    host,peer=s.st_client(adress)
    love.window.setMode(720,720,{vsync=1})
    CMD=love.thread.getChannel("cmd")
    THREAD_cmd=love.thread.newThread("cmd.lua")
    THREAD_cmd:start()
    snapshot={}
    input_key={"","","",""}
    connect=false
    my_nickname_accept=false
    my_nickname=d.nickname
    held_key={}
    my_id=0
    acc_dt_id=0
    acc_dt_rec=0
    acc_dt_input=0
    cmd_counter=1
    d.init(peer)
    print("Load Client complete\n|")
end
function love.keypressed(key)
    if not connect then return end
    if key=="w" or key=="a" or key=="s" or key=="d" then
        if held_key[key] then return end
        if key=="w" then
            input_key[1]="w"
            held_key[key]=true
        end
        if key=="a" then
            input_key[2]="a"
            held_key[key]=true
        end
        if key=="s" then
            input_key[3]="s"
            held_key[key]=true
        end
        if key=="d" then
            input_key[4]="d"
            held_key[key]=true
        end
        s.message_unr(peer,"key_input",input_key)
    end
end
function love.keyreleased(key)
    if not connect then return end
    if key=="w" or key=="a" or key=="s" or key=="d" then
        if not held_key[key] then return end
        if key=="w" then
            input_key[1]=""
            held_key[key]=nil
        end
        if key=="a" then
            input_key[2]=""
            held_key[key]=nil
        end
        if key=="s" then
            input_key[3]=""
            held_key[key]=nil
        end
        if key=="d" then
            input_key[4]=""
            held_key[key]=nil
        end
        s.message_unr(peer,"key_input",input_key)
    end
end
function love.update(dt)
    local COM=CMD:pop()
    if COM then
        local command,err=loadstring(COM)
        print("|")
        if command then
            local command_2,err_2=pcall(command)
            if command_2 then
            print("CMD complete: "..tostring(command_2).." | command conter: "..cmd_counter.."\n|")
            else
                print("CMD error: "..err_2.." | command counter: "..cmd_counter.."\n|")
            end
            cmd_counter=cmd_counter+1
        end
    end
    if connect then
        local event=s.event_collect()
        for _, input in ipairs(event) do
            if input.action=="connect" then
                if input.peer then peer=input.peer end
                s.message(peer,"my_id",{})
                connect=true
                print("connect for adress: "..adress.."\n|")
            elseif input.action=="disconnect" then
                snapshot={}
                my_id=0
                connect=false
                flag_disconnect=true
                held_key={}
                peer=nil
            elseif input.action=="receive" then
                if input.data.type=="test_physic" then
                    local snapshot_in=input.data.data[1]
                    snapshot=snapshot_in
                elseif input.data.type=="your_id" then
                    my_id=input.data.data[1]
                elseif input.data.type=="my_nickname" then
                    if input.data.data[1]==my_nickname then
                        my_nickname_flag=true
                    else
                        s.message(peer,"my_nickname",my_nickname)
                    end
                end
            end
        end
        if connect and my_id==0 then
            acc_dt_id=acc_dt_id+dt
            if acc_dt_id>=1 then
                s.message(peer,"my_id",{})
                acc_dt_id=0
            end
        end
        if flag_disconnect then
            acc_dt_rec=acc_dt_rec+dt
            if acc_dt_rec>=time_reconnect then
                host:connect(adress)
                flag_disconnect=false
                print("connect for adress: "..adress.."\n|")
                acc_dt_rec=0
            end
        end
        if next(held_key) and in_game then
            acc_dt_input=acc_dt_input+dt
            if acc_dt_input>=0.05 then
                s.message_unr(peer,"key_input",input_key)
                acc_dt_input=0
            end
        end
    end
end
function love.draw()
    love.graphics.clear()
    love.graphics.setColor(1,1,1)
    if connect then
        love.graphics.print("my_id: "..my_id,8,8)
        for key, obj in pairs(snapshot) do
            if obj.type=="player" then
                love.graphics.setColor(1,1,1)
                if my_id~=key then
                    love.graphics.print("id: "..key.." type: player",obj.x-40,obj.y-40)
                    love.graphics.print(snapshot.nickname,obj.x-40,obj.y-62)
                else
                    love.graphics.print(my_nickname,obj.x-20,obj.y-40)
                end
                love.graphics.setColor(1,0,0)
                love.graphics.circle("fill",obj.x,obj.y,25)
            end
        end
    else
        love.graphics.print("NOT IN GAME. NOT CONNECT",16,16)
    end
end
function love.quit()
    if peer and peer:state()=="connected" then
        peer:disconnect()
        host:flush()
    end
end