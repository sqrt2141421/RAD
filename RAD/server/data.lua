local drag=math.sqrt(2)/2
local data={
    cmd=[[
    local cmd_out=love.thread.getChannel("cmd")
    while true do
        local com=io.read()
        if not com then break end
        cmd_out:push(com)
    end
    ]],
    norm_vec={
        [1]={
            [1]={ax=-drag,ay=-drag},
            [2]={ax=-1,ay=0},
            [3]={ax=-drag,ay=drag}
        },
        [2]={
            [1]={ax=0,ay=-1},
            [2]={ax=0,ay=0},
            [3]={ax=0,ay=1}
        },
        [3]={
            [1]={ax=drag,ay=-drag},
            [2]={ax=1,ay=0},
            [3]={ax=drag,ay=drag}
        }
    },
    adress_servers={
        "0.0.0.0:5555",
        "0.0.0.0:4444"
    },
    accel=500,
    max_speed2=62500,
    max_speed=250,
    ovsp_fri=3,
    fri=5,
}
local world, px, py, vpx, vpy, apx, apy, mass, static, chunk, free_id
function data.init(world1,px1,py1,vpx1,vpy1,apx1,apy1,mass1,static1,chunk1,free_id1)
    mass=mass1
    world=world1
    chunk=chunk1
    static=static1
    free_id=free_id1
    px=px1;    py=py1
    vpx=vpx1;vpy=vpy1
    apx=apx1;apy=apy1
end
function data.delete(id)
    world.world[id]={type="empty"}
    mass[id]=0
    static[id]="None"
    px[id]=0;py[id]=0
    vpx[id]=0;vpy[id]=0
    apx[id]=0;apy[id]=0
    free_id[#free_id+1]=id
end
function data.spawn_entity(mass1,x,y,state)
    local id
    if #free_id>=1 then
        id=free_id[#free_id]
        free_id[#free_id]=nil
    else
        id=world.next_id
        world.next_id=world.next_id+1
    end
    mass[id]=mass1
    static[id]=state
    px[id]=x;py[id]=y
    vpx[id]=0;vpy[id]=0
    apx[id]=0;apy[id]=0
    return id
end
function data.normalized(dx,dy)
    local dx1=math.max(math.min(dx,1),-1)
    local dy1=math.max(math.min(dy,1),-1)
    return data.norm_vec[dx1+2][dy1+2]
end
function data.physic(dt)
    local snapshot={}
    for id, object in pairs(world.world) do
        if object.type=="player" then
            vpx[id]=vpx[id]+apx[id]*dt
            vpy[id]=vpy[id]+apy[id]*dt
            if apx[id]==0 and apy[id]==0 then
                local fri=1-data.fri*dt
                if fri<0 then fri=0 end
                vpx[id]=vpx[id]*fri
                vpy[id]=vpy[id]*fri
            end
            local sp2=vpx[id]*vpx[id]+vpy[id]*vpy[id]
            if sp2>data.max_speed2 then
                local ovsp_fri=1-data.ovsp_fri*dt
                if ovsp_fri<0 then ovsp_fri=0 end
                vpx[id]=vpx[id]*ovsp_fri
                vpy[id]=vpy[id]*ovsp_fri
            end
            px[id]=px[id]+vpx[id]*dt
            py[id]=py[id]+vpy[id]*dt
            apx[id]=0; apy[id]=0
            snapshot[id]={type="player",nickname=object.nickname,id=id,x=px[id],y=py[id],vx=vpx[id],vy=vpy[id]}
        end
    end
    return snapshot
end
return data