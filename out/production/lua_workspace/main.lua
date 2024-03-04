function PostExtract(fields, tables, ctx)
    local items
    if not tables.Records then
        items = ctx:CreateTable()
        items:AppendColumn('Date', 'Date')
        items:AppendColumn('Description', 'Transaction Details')
        items:AppendColumn('DepositAmount', 'Deposits')
        items:AppendColumn('WithdrawalAmount', 'Withdrawals')
        items:AppendColumn('Reference', 'Balance')
        items:AppendColumn('AccountNo', 'Account Number')
        tables['Records'] = items
    else
        items = tables.Records
    end
    if fields._TableAnchor0 and fields._TableAnchor1 and fields._TableAnchor2 and fields._TableAnchor3 and fields._TableAnchor4 then
        local text = ctx['text']
        local y0 = fields._Anchor0 and fields._Anchor0.BBox.Bottom or text.BBox.Top
        local y1 = fields._Anchor1 and fields._Anchor1.BBox.Top or text.BBox.Bottom
        text = text:GetArea(text.BBox.Left, y0, text.BBox.Right, y1)
        if text.Length > 0 then
            for i = 0, text.Length - 1 do
                local row = text[i]:ToString()
                local accountFound = false
                local newAccount = row:match('[%d%-]+')
                local descriptionRightAnchorPoint = fields._TableAnchor2.BBox.Left - (fields._TableAnchor2.BBox.Right - fields._TableAnchor2.BBox.Left)
                local depositRightAnchorPoint = fields._TableAnchor2.BBox.Right + (fields._TableAnchor2.BBox.Right - fields._TableAnchor2.BBox.Left) / 4
                local dateRightAnchorPoint = fields._TableAnchor1.BBox.Left - (fields._TableAnchor0.BBox.Right - fields._TableAnchor0.BBox.Left) / 4
                local referenceRightAnchorPoint = fields._TableAnchor4.BBox.Right + (fields._TableAnchor0.BBox.Right - fields._TableAnchor0.BBox.Left) / 4
                if i < text.Length - 1 and newAccount and text[i + 1]:ToString():match('Transaction%s+Details') then
                    fields._CurrentAccount = newAccount
                    accountFound = true
                end
                local date = text[i]:WhereWordLeftGT(text.BBox.Left):WhereWordRightLE(fields._TableAnchor1.BBox.Left):ToString()
                local description = text[i]:WhereWordLeftGT(dateRightAnchorPoint):WhereWordRightLE(descriptionRightAnchorPoint)
                local deposit = text[i]:WhereWordLeftGT(descriptionRightAnchorPoint):WhereWordRightLE(depositRightAnchorPoint):ToString()
                local withdrawal = text[i]:WhereWordLeftGT(fields._TableAnchor2.BBox.Right):WhereWordRightLE(fields._TableAnchor4.BBox.Left):ToString()
                local reference = text[i]:WhereWordLeftGT(fields._TableAnchor3.BBox.Right):WhereWordRightLE(referenceRightAnchorPoint):ToString()
                local dd, mon, yyyy = date:gsub('[%p%s]+', ''):match('(%d+)([A-Za-z][A-Za-z][A-Za-z])(%d%d%d%d)')
                if fields._CurrentAccount and not accountFound then
                    items:AppendRow()
                    if dd and mon and yyyy then
                        items[-1].Date = ctx:CreateDate(dd .. mon .. yyyy, 'ddmonyyyy')
                    end
                    items[-1].Description = description or nil
                    items[-1].DepositAmount = CorrectNumberFormat(deposit, ctx)
                    items[-1].WithdrawalAmount = CorrectNumberFormat(withdrawal, ctx)
                    items[-1].Reference = CorrectNumberFormat(reference, ctx)
                    items[-1].AccountNo = fields._CurrentAccount
                end
            end
        end
    end
end
function Finalize(fields, tables, ctx)
    if tables.Records then
        local items = tables.Records
        local localDate
        local strSum = ''
        local outerItems = { 'BALANCE%s+CARRIED%s+FORWARD', 'SAVINGS', 'Transaction%s+Details', 'Transaction%s+Turnover', 'Transaction%s+Count', 'CLOSING%s+BALANCE' }
        for i = items.Length - 1, 0, -1 do
            for j = 1, #outerItems do
                if items[i].Description.Text:match(outerItems[j]) or not items[i].Description.Value or string.len(items[i].Description.Text) == 0 then
                    items:RemoveRow(i)
                    break
                end
            end
        end
        for i = 0, items.Length - 1 do
            if items[i].Date.Value then
                localDate = items[i].Date.Value
            else
                if localDate then
                    items[i].Date = localDate
                end
            end
        end
        for i = 0, items.Length - 1 do
            if not items[i].Reference.Value then
                strSum = items[i].Description.Value and (strSum .. ' ' .. items[i].Description.Text) or strSum
            else
                items[i].Description = items[i].Description.Value and (strSum .. ' ' .. items[i].Description.Text) or strSum
                strSum = ''
            end
        end
        for i = items.Length - 1, 0, -1 do
            if not items[i].Reference.Value then
                items:RemoveRow(i)
            end
        end
        if tables.TransactionsBalance then
            local currency = 'Undefined'
            local account = ctx:CreateTable()
            account:AppendColumn('Date')
            account:AppendColumn('Description')
            account:AppendColumn('WithdrawalAmount', 'Debit')
            account:AppendColumn('DepositAmount', 'Credit')
            account:AppendColumn('Reference', 'Balance')
            tables['Transactions' .. currency] = account
            local transactions = tables.TransactionsBalance
            transactions:InsertColumnAt('ClosingBalance', 'OpeningBalance', 'Opening Balance')
            for i = 0, items.Length - 1 do
                local truncateAnchor = items[i].Description.Text:match('securities%s+provided%s+in%s+this%s+statement')
                local broughtForward = items[i].Description.Text:match('BALANCE%s+BROUGHT%s+FORWARD')
                if truncateAnchor then
                    break
                end
                for j = 0, transactions.Length - 1 do
                    local localAccount = items[i].AccountNo.Text
                    local balanceCode = transactions[j].CurrencyCode.Text
                    local balanceAccount = transactions[j].AccountNo.Text
                    if localAccount and balanceAccount and localAccount == balanceAccount and balanceCode and balanceCode ~= currency then
                        if broughtForward and not transactions[j].OpeningBalance.Value then
                            transactions[j].OpeningBalance = items[i].Reference.Value or nil
                        end
                        currency = balanceCode
                        account = ctx:CreateTable()
                        account:AppendColumn('Date')
                        account:AppendColumn('Description')
                        account:AppendColumn('WithdrawalAmount', 'Debit')
                        account:AppendColumn('DepositAmount', 'Credit')
                        account:AppendColumn('Reference', 'Balance')
                        tables['Transactions' .. currency] = account
                    end
                end
                if not broughtForward then
                    account:AppendRow()
                    account[-1].Date = items[i].Date.Value or nil
                    account[-1].Description = items[i].Description.Text or nil
                    account[-1].WithdrawalAmount = items[i].WithdrawalAmount.Value or nil
                    account[-1].DepositAmount = items[i].DepositAmount.Value or nil
                    account[-1].Reference = items[i].Reference.Value or nil
                end
            end
        end
    end
    tables.Records = nil
end
function CorrectNumberFormat(str, ctx)
    local decimal = str:gsub('%D+', ''):match('^%d+$')
    if decimal then
        decimal = ctx:CreateDecimal(decimal) / 100
        decimal = decimal:Round(2)
        if str:match('DR') then
            return decimal * -1
        else
            return decimal
        end
    else
        return nil
    end
end