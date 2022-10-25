function issolid(x,y)
    return fget(mget(x/8,y/8),0)
end

function solidarea(x,y,w,h)
    return issolid(x,y)
        or issolid(x+w,y)
        or issolid(x,y+h)
        or issolid(x+w,y+h)
end