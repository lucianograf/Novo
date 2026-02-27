#Include 'Protheus.ch'

User Function MT410INCL()
Local lIncluir := .T.

// Lógica para desabilitar: Ex: se usuário for '000001'
If cUsername == "000003"
    lIncluir := .F. // Botão Incluir ficará desabilitado
EndIf

Return lIncluir
