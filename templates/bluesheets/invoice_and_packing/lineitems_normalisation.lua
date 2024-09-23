function Finalize(fields, tables, ctx)
    if fields.ETA then
        fields.ATA = fields.ETA
    end
    if fields.CountryOrigin then
        local placeReceipt, country = fields.CountryOrigin.Text:match('([A-Z%s%d%p]+)%s*%,%s*([A-Z%s%d%p]+)')
        fields.PlaceOfReceipt = placeReceipt or nil
        fields.CountryOrigin = country or nil
    end
    if fields.CountrySource then
        local placeDelivery, country = fields.CountrySource.Text:match('([A-Z%s%d%p]+)%s*%,%s*([A-Z%s%d%p]+)')
        fields.FinalDestination = placeDelivery or nil
        fields.CountrySource = country or nil
    end
    if tables.LineItems then
        local items = tables.LineItems
        items:AppendColumn('Type')
        for i = 0, items.Length - 1 do
            local incoterms = not items[i].Total.Value and not items[i].Description.Value and items[i].UnitPrice.Text:match('^[A-Z][A-Z][A-Z]')
            local lostDescription = items[i].Description.Value and not items[i].Total.Value and items[i].Description.Text or nil
            if lostDescription and items[i].Total.Value then
                items[i].Description = items[i].Description.Value and lostDescription .. ' ' .. items[i].Description.Text or nil
            end
            if incoterms then
                fields.Incoterms = incoterms
            end
            items[i].UnitPrice = items[i].UnitPrice.Value and CastToDecimal(items[i].UnitPrice.Text, ctx) or nil
            items[i].Type = 'Goods'
        end
        NormaliseLineItems(tables, items, ctx)
    end
end
function CastToDecimal(str, ctx)
    local decimal = str:gsub('[%s%,]+', ''):match('[%d%.]+')
    return decimal and ctx:CreateDecimal(decimal) or nil
end
function NormaliseLineItems(tables, table, ctx)
    local items = ctx:CreateTable()
    items:AppendColumn('No', 'No.')
    items:AppendColumn('PoNo', 'P/O No.')
    items:AppendColumn('PartNumber', 'Part Number')
    items:AppendColumn('Descriptions', 'Descriptions')
    items:AppendColumn('Model', 'Model')
    items:AppendColumn('Quantity', 'Quantity')
    items:AppendColumn('UnitPrice', 'Unit Price')
    items:AppendColumn('Amount', 'Amount')
    items:AppendColumn('Type', 'Type')
    tables['LineItems'] = items
    local linesCounter = 0
    for i = 0, table.Length - 1 do
        if table[i].Total.Value and table[i].Description.Value then
            linesCounter = linesCounter + 1
            items:AppendRow()
            items[-1].No = table[i].ItemNo and table[i].ItemNo.Value and table[i].ItemNo.Text or linesCounter
            items[-1].Type = table[i].Type and table[i].Type.Value and table[i].Type.Text or nil
            items[-1].PartNumber = table[i].PartNumber and table[i].PartNumber.Value and table[i].PartNumber.Text or nil
            items[-1].PoNo = table[i].PoNumber and table[i].PoNumber.Value and table[i].PoNumber.Text or nil
            items[-1].Descriptions = table[i].Description and table[i].Description.Value and table[i].Description.Text or nil
            items[-1].Quantity = table[i].Qty and table[i].Qty.Value or nil
            items[-1].UnitPrice = table[i].UnitPrice and table[i].UnitPrice.Value or nil
            items[-1].Amount = table[i].Total and table[i].Total.Value or nil
        end
    end
end