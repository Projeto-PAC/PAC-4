local Util = {}

-- gera decimal com até 2 casas
function Util.decimal(min,max)

	local n = math.random(min*100,max*100)/100
	return Util.arredondar(n)

end

-- arredondar para 2 casas
function Util.arredondar(n)

	return math.floor(n*100+0.5)/100

end

-- formatar número no padrão brasileiro
function Util.formatarNumero(n)

	n = Util.arredondar(n)

	local texto = string.format("%.2f",n)

	texto = texto:gsub("%.",",")

	-- remove ,00
	texto = texto:gsub(",00","")

	-- remove zero final (ex: 2,50 → 2,5)
	texto = texto:gsub("(%d),(%d)0$","%1,%2")

	return texto

end

-- gerar opções
function Util.gerarOpcoes(resposta)

	local opcoes = {resposta}

	while #opcoes < 4 do

		local falso = resposta + math.random(-10,10)

		falso = Util.arredondar(falso)

		local existe = false

		for _,v in pairs(opcoes) do
			if v == falso then
				existe = true
			end
		end

		if not existe then
			table.insert(opcoes,falso)
		end

	end

	for i=#opcoes,2,-1 do
		local j=math.random(i)
		opcoes[i],opcoes[j]=opcoes[j],opcoes[i]
	end

	return opcoes

end

return Util