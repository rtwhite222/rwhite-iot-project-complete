function selectQueryWhere(getValues,SQLtable,compareValue,compareCheck)
    local sql = ""
    for value, getValues in ipairs(getValues) do
        if(value == 1) then
            sql = getValues
        else
            sql = sql .. ", " .. getValues
        end
    end
    
    sql = sql .. " FROM " .. SQLtable .. " WHERE " .. compareValue .. " = '" .. compareCheck .. "';"
    return sql
end
-- Function to create string to be input as SQL select with inputs for WHERE comparisons. Only allows for 1 compare

function selectQueryWhereMult(getValues,SQLtable,compareValues,compareCheck)
    local sql = ""
    for value, getValues in ipairs(getValues) do
        if(value == 1) then
            sql = getValues
        else
            sql = sql .. ", " .. getValues
        end
    end
    sql = sql .. " FROM " .. SQLtable
    for value, compareValues in ipairs(compareValues) do
        if(value == 1) then
            sql = sql .. " WHERE " .. compareValues .. " = '" .. compareCheck[value] .. "'"
        else
            sql = sql .. " AND " .. compareValues .. " = '" .. compareCheck[value] .. "'"
        end
    end
    
         sql = sql .. ";"
    
    return sql
end
    
function selectQuery(getValues,SQLtable)
    local sql = ""
    for value, getValues in ipairs(getValues) do
        if(value == 1) then
            sql = getValues
        else
            sql = sql .. ", " .. getValues
        end
    end
    sql = sql .. " FROM " .. SQLtable
    return sql
end
-- Function to create string to be input as SQL select

function updateQueryWhere(getValues,SQLtable, compareValue, compareCheck)
    local sql = "UPDATE " .. SQLtable .. " SET "
    local checked = false
    
    for name, value in pairs(getValues) do
        --trace(value)
        if not (value == "") then
            if not checked then
                sql = sql .. name .. " = '" .. value .. "'" 
                checked = true
            else
                sql = sql .. ", " .. name .. " = '" .. value .. "'"
            end
        end
    end
    sql = sql .. " WHERE " .. compareValue .. " = '" .. compareCheck .. "';"
    return sql
end
-- Function to create string to be input as SQL update. Used to change values of already created entities
function updateQueryWhereMult(getValues,SQLtable, compareValues, compareCheck)
    local sql = "UPDATE " .. SQLtable .. " SET "
    local checked = false
    
    for name, value in pairs(getValues) do
        --trace(value)
        if not (value == "") then
            if not checked then
                sql = sql .. name .. " = '" .. value .. "'" 
                checked = true
            else
                sql = sql .. ", " .. name .. " = '" .. value .. "'"
            end
        end
    end
    for value, compareValues in ipairs(compareValues) do
        if(value == 1) then
            sql = sql .. " WHERE " .. compareValues .. " = '" .. compareCheck[value] .. "'"
        else
            sql = sql .. " AND " .. compareValues .. " = '" .. compareCheck[value] .. "'"
        end
    end
    
         sql = sql .. ";"
    return sql
end

function deleteQueryWhere(SQLtable, attribute, entity)
    local sql = "DELETE FROM " .. SQLtable .. " WHERE " .. attribute .. " = '" .. entity .. "';"
    return sql
end

function insertQuery(getValues,SQLtable)
    local sql = "INSERT INTO " .. SQLtable .. "("
    local checked = false
    for name, value in pairs(getValues) do
        if not checked then
            sql = sql .. name 
            sqlvalues = "'"..value.."'"
            checked = true
        else
            sql = sql .. ", " .. name
            sqlvalues = sqlvalues .. ", '" .. value .. "'"
        end
    end
    sql = sql .. ") VALUES (" .. sqlvalues .. ");"
    return sql
end
