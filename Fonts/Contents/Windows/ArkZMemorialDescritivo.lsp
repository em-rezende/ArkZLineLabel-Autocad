;;;===========================================================================
;;; ArkZMemorialDescritivo.lsp (Versão com Interface DCL, CSV e Memorial Descritivo)
;;; Version: 2.3 - Com Seleção de Cidade, Fuso Automático e Melhorias
;;; Author: Ezequiel M. Rezende
;;; Início:  2026/08/01 - Version 1.0
;;; Revisão: 2026/09/08 - Revisão geral
;;; Revisão: 2026/09/10 - Correção função ArkZ:NormalizarParaOrdenacao
;;;===========================================================================

(vl-load-com)

;;;===========================================================================
;;; VARIÁVEIS GLOBAIS
;;;===========================================================================
(setq *ArkZ_Mode*        "mode_sel"
      *ArkZ_TogPoly*     "1"
      *ArkZ_TogVtx*      "1"
      *ArkZ_TogAzi*      "1"
      *ArkZ_TogTab*      "1"
      *ArkZ_LayVtx*      "TGVERTICE"
      *ArkZ_LayAzi*      "TGCOTA"
      *ArkZ_LayTab*      "TGTABELA"
	  *ArkZ_HVtx*        "0.5"
	  *ArkZ_HAzi*        "0.5"
      *ArkZ_HTab*        "0.5"
      *ArkZ_DecVtx*      "2"
      *ArkZ_DecAzi*      "2"
      *ArkZ_DecTab*      "2"
      *ArkZ_CsvPath*     ""
      *ArkZ_CsvSep*      "0"
      *ArkZ_CsvSkip*     "0"
      *ArkZ_ColX*        "0"
      *ArkZ_ColY*        "1"
      *ArkZ_NomeLote*    "Lote 01 da quadra 01 do Bairro Centro"
      *ArkZ_Municip*     "Belo Horizonte, MG"
      *ArkZ_TogMemMText* "1"
      *ArkZ_TogMemTxt*   "0"
      *ArkZ_Fuso*        "23S"
      *ArkZ_Meridiano*   "45°00' W"
	  *ArkZ_CityData*    nil
      *ArkZ_Debug*       "0"
	  *ArkZ_InvertDir*   "0"  ; "0" = Normal (Horário), "1" = Invertido (Anti-horário)
	  *ArkZ_StartVtxIdx* 0  ; Índice base (0-based) para o vértice inicial V1
	  *ArkZ_PLineEnt*    nil  ; Entidade da Polilinha Selecionada
      *ArkZ_PLinePts*    nil  ; Lista de Pontos da Polilinha
      *ArkZ_StartVtxIdx* 0    ; Índice base 0 do V1
      *ArkZ_InvertDir*   "0"  ; "0" = Sentido Horário, "1" = Anti-horário
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:DestacarVertice - Desenha marca no vértice
;;;===========================================================================
(defun ArkZ:DestacarVertice (pt / size)
  "Desenha uma marca temporária destacada no vértice do AutoCAD"
  (redraw)
  (setq size (/ (getvar "VIEWSIZE") 30.0))
  (grdraw (list (- (car pt) size) (- (cadr pt) size)) 
          (list (+ (car pt) size) (+ (cadr pt) size)) 1 1)
  (grdraw (list (- (car pt) size) (+ (cadr pt) size)) 
          (list (+ (car pt) size) (- (cadr pt) size)) 1 1)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:AtualizarStatusSentido - Atualiza o status no DCL
;;;===========================================================================
(defun ArkZ:AtualizarStatusSentido ()
  "Atualiza o texto de status do sentido no DCL"
  (if (= *ArkZ_InvertDir* "0")
    (set_tile "txt_sentido_status" "Sentido: Horário")
    (set_tile "txt_sentido_status" "Sentido: Anti-horário")
  )
  (princ)
)

;;;===========================================================================
;;; COMANDO PRINCIPAL - VERSÃO CORRIGIDA
;;;===========================================================================
(defun c:ArkZMemorialDescritivo (/ dcl_id status sel resp points_list)
  (vl-load-com)
  
  ;; Salvar zona atual
  (c:ArkZSaveZone)
  
  ;; Carregar o DCL
  (setq dcl_id (load_dialog "ArkZMemorialDescritivo.dcl"))
  (if (not dcl_id)
    (progn
      (alert "Erro ao carregar o arquivo ArkZMemorialDescritivo.dcl!")
      (exit)
    )
  )
  
  ;; Loop principal do diálogo
  (setq status 1)
  (while (> status 0)
    (if (not (new_dialog "ArkZMemorialDescritivo" dcl_id))
      (exit)
    )
	
    (mode_tile "#arkz" 1)
    (MD_ShowSld "#img_logo" "ArkZMemorialDescritivo" "ArkZLogo" -2)
    (MD_ShowSld "sep1" "ArkZMemorialDescritivo" "Separato" -2)
    (MD_ShowSld "sep2" "ArkZMemorialDescritivo" "Separato" -2)

    ;; Preencher campos do DCL
    (set_tile "eb_nome_lote"   *ArkZ_NomeLote*)
    (set_tile "eb_municipio"   *ArkZ_Municip*)
    (set_tile "tg_mem_mtext"   *ArkZ_TogMemMText*)
    (set_tile "tg_mem_txt"     *ArkZ_TogMemTxt*)
    (set_tile "tog_poly"       *ArkZ_TogPoly*)
    (set_tile "tog_vtx"        *ArkZ_TogVtx*)
    (set_tile "tog_azi"        *ArkZ_TogAzi*)
    (set_tile "tog_tab"        *ArkZ_TogTab*)
    (set_tile "lay_vtx"        *ArkZ_LayVtx*)
    (set_tile "lay_azi"        *ArkZ_LayAzi*)
    (set_tile "lay_tab"        *ArkZ_LayTab*)
    (set_tile "h_vtx"          *ArkZ_HVtx*)
    (set_tile "h_azi"          *ArkZ_HAzi*)
    (set_tile "h_tab"          *ArkZ_HTab*)
    (set_tile "dec_vtx"        *ArkZ_DecVtx*)
    (set_tile "dec_azi"        *ArkZ_DecAzi*)
    (set_tile "dec_tab"        *ArkZ_DecTab*)
    (set_tile "txt_fuso_display"      *ArkZ_Fuso*)
    (set_tile "txt_meridiano_display" *ArkZ_Meridiano*)
    
    ;; Atualizar informaçoes de navegação
    (if *ArkZ_PLinePts*
      (progn
        (set_tile "txt_total_vtx" (itoa (length *ArkZ_PLinePts*)))
        (set_tile "txt_v1_display" (itoa (1+ *ArkZ_StartVtxIdx*)))
      )
      (progn
        (set_tile "txt_total_vtx" "0")
        (set_tile "txt_v1_display" "-")
      )
    )
    
    (UpdateDCLFields)
    
    ;; =============================================================
    ;; AÇÕES DOS BOTÕES
    ;; =============================================================
    
    ;; BOTÃO: Selecionar Poligonal - APENAS SELECIONA, NÃO PROCESSA
    (action_tile "mode_sel"
      "(setq *ArkZ_Mode* \"mode_sel\") (done_dialog 2)"
    )
    
    ;; BOTÃO: Importar CSV
    (action_tile "mode_csv"
      "(setq *ArkZ_Mode* \"mode_csv\") (done_dialog 3)"
    )
    
    ;; BOTÃO: Aplicar
    (action_tile "btn_apply"
      "(setq *ArkZ_NomeLote*    (get_tile \"eb_nome_lote\")
             *ArkZ_Municip*     (get_tile \"eb_municipio\")
             *ArkZ_TogMemMText* (get_tile \"tg_mem_mtext\")
             *ArkZ_TogMemTxt*   (get_tile \"tg_mem_txt\")
             *ArkZ_TogPoly*     (get_tile \"tog_poly\")
             *ArkZ_TogVtx*      (get_tile \"tog_vtx\")
             *ArkZ_TogAzi*      (get_tile \"tog_azi\")
             *ArkZ_TogTab*      (get_tile \"tog_tab\")
             *ArkZ_LayVtx*      (strcase (get_tile \"lay_vtx\"))
             *ArkZ_LayAzi*      (strcase (get_tile \"lay_azi\"))
             *ArkZ_LayTab*      (strcase (get_tile \"lay_tab\"))
             *ArkZ_HVtx*        (get_tile \"h_vtx\")
             *ArkZ_HAzi*        (get_tile \"h_azi\")
             *ArkZ_HTab*        (get_tile \"h_tab\")
             *ArkZ_DecVtx*      (get_tile \"dec_vtx\")
             *ArkZ_DecAzi*      (get_tile \"dec_azi\")
             *ArkZ_DecTab*      (get_tile \"dec_tab\"))
       (done_dialog 4)"
    )
    
    ;; BOTÃO: Vértice Avulso
    (action_tile "btn_vtx_avulso"
      "(setq *ArkZ_LayVtx* (strcase (get_tile \"lay_vtx\"))
             *ArkZ_HVtx*   (get_tile \"h_vtx\")
             *ArkZ_DecVtx* (get_tile \"dec_vtx\")) (done_dialog 5)"
    )
    
    ;; BOTÃO: Azimute Avulso
    (action_tile "btn_azi_avulso"
      "(setq *ArkZ_LayAzi* (strcase (get_tile \"lay_azi\"))
             *ArkZ_HAzi*   (get_tile \"h_azi\")
             *ArkZ_DecAzi* (get_tile \"dec_azi\")) (done_dialog 6)"
    )
    
    ;; BOTÃO: Detectar Civil 3D
    (action_tile "btn_detect_c3d"
      "(setq c3d_zone (ArkZ:GetCivil3DZone))
       (if c3d_zone
         (progn
           (setq *ArkZ_Fuso* (car c3d_zone)
                 *ArkZ_Meridiano* (cadr c3d_zone))
           (set_tile \"txt_fuso_display\" *ArkZ_Fuso*)
           (set_tile \"txt_meridiano_display\" *ArkZ_Meridiano*)
         )
         (alert \"Nenhum sistema de coordenadas UTM ativo foi encontrado.\")
       )"
    )
    
    ;; BOTÃO: Selecionar Cidade
    (action_tile "btn_select_city"
      "(setq city_data (ArkZ:SelectCity))
       (if city_data
         (progn
           (setq *ArkZ_Fuso* (nth 4 city_data))
           (setq *ArkZ_Meridiano* (nth 5 city_data))
           (setq *ArkZ_Municip* (strcat (nth 1 city_data) \", \" (ArkZ:GetStateName (substr (nth 0 city_data) 1 2))))
           (set_tile \"txt_fuso_display\" *ArkZ_Fuso*)
           (set_tile \"txt_meridiano_display\" *ArkZ_Meridiano*)
           (set_tile \"eb_municipio\" *ArkZ_Municip*)
           (c:ArkZSaveZone)
         )
       )"
    )
    
    ;; BOTÃO: Navegar Vértices (Anterior)
    (action_tile "btn_prev_vtx"
      "(if *ArkZ_PLinePts*
         (progn
           (setq total (length *ArkZ_PLinePts*))
           (setq *ArkZ_StartVtxIdx* (rem (+ *ArkZ_StartVtxIdx* (1- total)) total))
           (ArkZ:DestacarVertice (nth *ArkZ_StartVtxIdx* *ArkZ_PLinePts*))
           (set_tile \"txt_v1_display\" (itoa (1+ *ArkZ_StartVtxIdx*)))
		   (ArkZ:AtualizarStatusSentido)
         )
         (alert \"Nenhuma polilinha selecionada!\")
       )"
    )
    
    ;; BOTÃO: Navegar Vértices (Próximo)
    (action_tile "btn_next_vtx"
      "(if *ArkZ_PLinePts*
         (progn
           (setq total (length *ArkZ_PLinePts*))
           (setq *ArkZ_StartVtxIdx* (rem (1+ *ArkZ_StartVtxIdx*) total))
           (ArkZ:DestacarVertice (nth *ArkZ_StartVtxIdx* *ArkZ_PLinePts*))
           (set_tile \"txt_v1_display\" (itoa (1+ *ArkZ_StartVtxIdx*)))
		   (ArkZ:AtualizarStatusSentido)
         )
         (alert \"Nenhuma polilinha selecionada!\")
       )"
    )
    
    ;; BOTÃO: Inverter Direção
    (action_tile "btn_invert_dir"
      "(if *ArkZ_PLinePts*
         (progn
           (if (= *ArkZ_InvertDir* \"0\")
             (setq *ArkZ_InvertDir* \"1\")
             (setq *ArkZ_InvertDir* \"0\")
           )
           (ArkZ:AtualizarStatusSentido)
           (princ (strcat \"\\nSentido invertido: \" (if (= *ArkZ_InvertDir* \"1\") \"Anti-horario\" \"Horario\")))
         )
         (alert \"Nenhuma polilinha selecionada!\")
       )"
    )
    
    ;; BOTÃO: Ajuda
    (action_tile "help" "(ArkZMemorialDescritivo_Help)")
    
    ;; BOTÃO: Fechar
    (action_tile "cancel" "(done_dialog 0)")
    
    (setq status (start_dialog))
    
    ;; =============================================================
    ;; PROCESSAR AÇÕES
    ;; =============================================================
    (cond
      ;; Ação 2: Selecionar Poligonal - APENAS SELECIONA
      ((= status 2)
       (setq sel (car (entsel "\nSelecione a Polilinha desejada: ")))
       (if (and sel (= (cdr (assoc 0 (entget sel))) "LWPOLYLINE"))
         (progn
           (setq *ArkZ_PLineEnt* sel)
           (setq *ArkZ_PLinePts* 
                 (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= (car x) 10)) (entget sel))))
           (setq *ArkZ_StartVtxIdx* 0)
           (setq *ArkZ_InvertDir* "0")
           (princ (strcat "\n? Polilinha selecionada com " 
                          (itoa (length *ArkZ_PLinePts*)) " vértices"))
           ;; NÃO processa aqui - volta ao diálogo
         )
         (alert "Objeto inválido! Selecione uma LWPOLYLINE.")
       )
      )
      
      ;; Ação 3: Importar CSV
      ((= status 3)
       (setq points_list (ArkZ_ExecuteCSVDialog))
       (if (and points_list (>= (length points_list) 2))
         (progn
           (setq *ArkZ_PLinePts* points_list)
           (setq *ArkZ_PLineEnt* nil)
           (princ (strcat "\n? CSV importado com " (itoa (length points_list)) " pontos."))
           (princ "\nClique em 'Aplicar' para gerar as anotações.")
         )
         (princ "\nNenhum ponto válido importado!")
       )
      )
      
      ;; Ação 4: Aplicar - PROCESSA A POLILINHA JÁ SELECIONADA
      ((= status 4)
       (if *ArkZ_PLinePts*
         (progn
           ;; Reordenar pontos conforme V1 e sentido
           (setq pts_ordenados (ArkZ:ReordenarPontos 
                                 *ArkZ_PLinePts* 
                                 *ArkZ_StartVtxIdx* 
                                 *ArkZ_InvertDir*))
           (setq *ArkZ_PLinePts* pts_ordenados)
           
           ;; Processar a polilinha já selecionada (NÃO pede para selecionar novamente)
           (princ "\nProcessando polilinha selecionada...")
           (ArkZ:ProcessarPolilinha)
           (setq status 0) ; Fecha o loop
         )
         (alert "Selecione uma Polilinha antes de aplicar!")
       )
      )
      
      ;; Ação 5: Vértice Avulso
      ((= status 5) (c:ArkZVtx))
      
      ;; Ação 6: Azimute Avulso
      ((= status 6) (c:ArkZAzi))
      
      ;; Ação 0: Fechar
      ((= status 0) (princ "\nOperação finalizada."))
    )
  )

  (unload_dialog dcl_id)
  (princ)
)

;;;===========================================================================
;;; FUNÇÃO: c:ArkZMemorialDescritivoSel - Seleção de Polilinha com Navegação de Vértices
;;;===========================================================================
(defun c:ArkZMemorialDescritivoSel (/ dcl_id action sel)
  "Função separada para o modo de seleção com navegação de vértices"
  
  (setq dcl_id (load_dialog "ArkZMemorialDescritivo.dcl"))
  (if (not dcl_id)
    (progn
      (alert "Erro ao carregar o arquivo ArkZMemorialDescritivo.dcl!")
      (exit)
    )
  )
  
  (setq action 1)
  
  (while (> action 0)
    (if (not (new_dialog "ArkZMemorialDescritivo" dcl_id))
      (exit)
    )

    ;; Atualiza status da polilinha
    (if *ArkZ_PLineEnt*
      (set_tile "txt_pline_status" "? Polilinha Selecionada")
      (set_tile "txt_pline_status" "?? Nenhuma polilinha")
    )
    (set_tile "eb_start_vtx" (itoa (1+ *ArkZ_StartVtxIdx*)))
    (set_tile "tog_invert_dir" *ArkZ_InvertDir*)
    
    ;; Preencher campos do DCL
    (set_tile "eb_nome_lote"   *ArkZ_NomeLote*)
    (set_tile "eb_municipio"   *ArkZ_Municip*)
    (set_tile "tg_mem_mtext"   *ArkZ_TogMemMText*)
    (set_tile "tg_mem_txt"     *ArkZ_TogMemTxt*)
    (set_tile "rad_mode"       *ArkZ_Mode*)
    (set_tile "tog_poly"       *ArkZ_TogPoly*)
    (set_tile "tog_vtx"        *ArkZ_TogVtx*)
    (set_tile "tog_azi"        *ArkZ_TogAzi*)
    (set_tile "tog_tab"        *ArkZ_TogTab*)
    (set_tile "lay_vtx"        *ArkZ_LayVtx*)
    (set_tile "lay_azi"        *ArkZ_LayAzi*)
    (set_tile "lay_tab"        *ArkZ_LayTab*)
    (set_tile "h_vtx"          *ArkZ_HVtx*)
    (set_tile "h_azi"          *ArkZ_HAzi*)
    (set_tile "h_tab"          *ArkZ_HTab*)
    (set_tile "dec_vtx"        *ArkZ_DecVtx*)
    (set_tile "dec_azi"        *ArkZ_DecAzi*)
    (set_tile "dec_tab"        *ArkZ_DecTab*)
    (set_tile "txt_fuso_display"      *ArkZ_Fuso*)
    (set_tile "txt_meridiano_display" *ArkZ_Meridiano*)
    
    (UpdateDCLFields)
 
    ;; Ações dos botões
    (action_tile "tog_invert_dir" "(setq *ArkZ_InvertDir* $value)")
    (action_tile "eb_start_vtx"   "(setq *ArkZ_StartVtxIdx* (1- (max 1 (atoi $value))))")
    
    ;; Botão Selecionar Polilinha
    (action_tile "btn_select_pline"
      "(done_dialog 2)"
    )
    
    ;; Botão Navegar Vértices
    (action_tile "btn_navegar_vtx"
      "(done_dialog 3)"
    )
    
    ;; Botão Aplicar
    (action_tile "btn_apply"
      "(setq *ArkZ_NomeLote*    (get_tile \"eb_nome_lote\")
             *ArkZ_Municip*     (get_tile \"eb_municipio\")
             *ArkZ_TogMemMText* (get_tile \"tg_mem_mtext\")
             *ArkZ_TogMemTxt*   (get_tile \"tg_mem_txt\")
             *ArkZ_Mode*        (get_tile \"rad_mode\")
             *ArkZ_TogPoly*     (get_tile \"tog_poly\")
             *ArkZ_TogVtx*      (get_tile \"tog_vtx\")
             *ArkZ_TogAzi*      (get_tile \"tog_azi\")
             *ArkZ_TogTab*      (get_tile \"tog_tab\")
             *ArkZ_LayVtx*      (strcase (get_tile \"lay_vtx\"))
             *ArkZ_LayAzi*      (strcase (get_tile \"lay_azi\"))
             *ArkZ_LayTab*      (strcase (get_tile \"lay_tab\"))
             *ArkZ_HVtx*        (get_tile \"h_vtx\")
             *ArkZ_HAzi*        (get_tile \"h_azi\")
             *ArkZ_HTab*        (get_tile \"h_tab\")
             *ArkZ_DecVtx*      (get_tile \"dec_vtx\")
             *ArkZ_DecAzi*      (get_tile \"dec_azi\")
             *ArkZ_DecTab*      (get_tile \"dec_tab\"))
       (done_dialog 4)"
    )
    
    ;; Botões originais
    (action_tile "btn_vtx_avulso"
      "(setq *ArkZ_LayVtx* (strcase (get_tile \"lay_vtx\"))
             *ArkZ_HVtx*   (get_tile \"h_vtx\")
             *ArkZ_DecVtx* (get_tile \"dec_vtx\")) (done_dialog 2)"
    )
    
    (action_tile "btn_azi_avulso"
      "(setq *ArkZ_LayAzi* (strcase (get_tile \"lay_azi\"))
             *ArkZ_HAzi*   (get_tile \"h_azi\")
             *ArkZ_DecAzi* (get_tile \"dec_azi\")) (done_dialog 3)"
    )
    
    (action_tile "btn_select_city"
      "(setq city_data (ArkZ:SelectCity))
       (if city_data
         (progn
           (setq *ArkZ_Fuso* (nth 4 city_data))
           (setq *ArkZ_Meridiano* (nth 5 city_data))
           (setq *ArkZ_Municip* (strcat (nth 1 city_data) \", \" (ArkZ:GetStateName (substr (nth 0 city_data) 1 2))))
           (set_tile \"txt_fuso_display\" *ArkZ_Fuso*)
           (set_tile \"txt_meridiano_display\" *ArkZ_Meridiano*)
           (set_tile \"eb_municipio\" *ArkZ_Municip*)
           (c:ArkZSaveZone)
         )
       )"
    )
    
    (action_tile "help"   "(ArkZMemorialDescritivo_Help)")
    (action_tile "cancel" "(done_dialog 0)")
    
    (setq action (start_dialog))
    
    ;; Processa as ações
    (cond
      ;; Ação 2: Selecionar Polilinha
      ((= action 2)
       (setq sel (car (entsel "\nSelecione a Polilinha desejada: ")))
       (if (and sel (= (cdr (assoc 0 (entget sel))) "LWPOLYLINE"))
         (progn
           (setq *ArkZ_PLineEnt* sel)
           (setq *ArkZ_PLinePts* 
                 (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= (car x) 10)) (entget sel))))
           (setq *ArkZ_StartVtxIdx* 0)
           (princ (strcat "\n? Polilinha selecionada com " 
                          (itoa (length *ArkZ_PLinePts*)) " vértices"))
         )
         (alert "Objeto inválido! Selecione uma LWPOLYLINE.")
       )
      )
      
      ;; Ação 3: Navegar Vértices
      ((= action 3)
       (ArkZ:NavegarVertices)
      )
      
      ;; Ação 4: Aplicar (gera anotações)
      ((= action 4)
       (if *ArkZ_PLinePts*
         (progn
           ;; Reordenar pontos conforme V1 e sentido
           (setq pts_ordenados (ArkZ:ReordenarPontos 
                                 *ArkZ_PLinePts* 
                                 *ArkZ_StartVtxIdx* 
                                 *ArkZ_InvertDir*))
           (setq *ArkZ_PLinePts* pts_ordenados)
           
           ;; Processar diretamente os pontos
           (princ "\nProcessando com V1 definido...")
           (ArkZ:ProcessarComPontos pts_ordenados)
           (setq action 0) ; Fecha o loop
         )
         (alert "Selecione uma Polilinha antes de aplicar!")
       )
      )
      
      ;; Ação 0: Cancelar
      ((= action 0)
       (princ "\nOperação cancelada.")
      )
    )
  )
  (unload_dialog dcl_id)
  (princ)
)


;;;===========================================================================
;;; FUNÇÃO: ArkZ:ReordenarPontos - Reordena lista de pontos
;;;===========================================================================
(defun ArkZ:ReordenarPontos (pts startIdx invert / len res i)
  "Reordena a lista de pontos iniciando pelo índice startIdx"
  (setq len (length pts))
  (if (and pts (> len 0))
    (progn
      (setq i 0 res nil)
      (repeat len
        (setq res (append res (list (nth (rem (+ startIdx i) len) pts))))
        (setq i (1+ i))
      )
      (if (= invert "1")
        (setq res (cons (car res) (reverse (cdr res))))
      )
      res
    )
    pts
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:VerificarCamada (DEFINIDA GLOBALMENTE)
;;;===========================================================================
(defun ArkZ:VerificarCamada (nomeColor / AcDoc layObj)
  "Verifica e cria a camada se não existir"
  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (if (null (tblsearch "LAYER" (car nomeColor)))
    (progn
      (setq layObj (vla-add (vla-get-layers AcDoc) (car nomeColor)))
      (vlax-put layObj 'Color (cadr nomeColor))
    )
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:StrToReal - Converte string com vírgula para número real
;;;===========================================================================
(defun ArkZ:StrToReal (str / result)
  "Converte string para número real, aceitando vírgula ou ponto como decimal"
  (if (and str (> (strlen str) 0))
    (progn
      (setq str (vl-string-translate "," "." str))
      (setq result (atof str))
      result
    )
    0.0
  )
)

;;;===========================================================================
;;; FUNÇÃO: MD_ShowSld
;;;===========================================================================
(defun MD_ShowSld (tile library slide color / x y)
  (and
    (setq x (dimx_tile tile))
    (setq y (dimy_tile tile))
    (start_image tile)
    (fill_image 0 0 x y color)
    (slide_image 0 0 x y (strcat library " (" (vl-filename-base slide) ")"))
    (end_image)
  )
  (princ)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:ParseZoneToFuso - Extrai fuso do código CGEOCS
;;;===========================================================================
(defun ArkZ:ParseZoneToFuso (str / len i char numStr hemisf)
  (if (and str (/= str ""))
    (progn
      (setq len (strlen str)
            i len
            numStr ""
            hemisf "")
      
      (setq char (strcase (substr str len 1)))
      (if (or (= char "N") (= char "S"))
        (progn
          (setq hemisf char
                i (1- len))
          (while (and (> i 0)
                      (setq char (substr str i 1))
                      (>= (ascii char) 48)
                      (<= (ascii char) 57))
            (setq numStr (strcat char numStr))
            (setq i (1- i))
          )
        )
      )
      
      (if (/= numStr "")
        (strcat numStr hemisf)
        nil
      )
    )
    nil
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:CalcularMeridianoCentral - Calcula o meridiano central
;;;===========================================================================
(defun ArkZ:CalcularMeridianoCentral (fusoStr / fusoNum mc)
  (if fusoStr
    (progn
      (setq fusoNum (atoi fusoStr))
      (if (and (>= fusoNum 1) (<= fusoNum 60))
        (progn
          (setq mc (- (* fusoNum 6) 183))
          (strcat (itoa (abs mc)) "°00' " (if (< mc 0) "W" "E"))
        )
        ""
      )
    )
    ""
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:GetCivil3DZone - Detecta zona via CGEOCS (NÃO TRAVA)
;;;===========================================================================
(defun ArkZ:GetCivil3DZone ( / zoneCode fuso mc)
  (vl-load-com)
  (setq zoneCode (getvar "CGEOCS"))
  (if (and zoneCode (/= zoneCode "") (/= zoneCode "UNSPECIFIED") (/= zoneCode "0"))
    (progn
      (setq fuso (ArkZ:ParseZoneToFuso zoneCode))
      (if fuso
        (progn
          (setq mc (ArkZ:CalcularMeridianoCentral fuso))
          (list fuso mc)
        )
        nil
      )
    )
    nil
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:SaveZoneToDWG - Salva a zona no dicionário do desenho
;;;===========================================================================
(defun c:ArkZSaveZone ( / fuso meridiano doc extDict dict)
  (vl-load-com)
  
  (if (null *ArkZ_Fuso*)
    (setq *ArkZ_Fuso* "22S")
  )
  (if (null *ArkZ_Meridiano*)
    (setq *ArkZ_Meridiano* "45°00' W")
  )
  
  (vl-catch-all-apply
    '(lambda ()
       (setq doc (vla-get-activedocument (vlax-get-acad-object)))
       (setq extDict (vla-GetExtensionDictionary doc))
       
       (if (vl-catch-all-error-p (vl-catch-all-apply 'vla-Item (list extDict "ARKZ")))
         (setq dict (vla-AddObject extDict "ARKZ" "AcDbDictionary"))
         (setq dict (vla-Item extDict "ARKZ"))
       )
       
       (vlax-ldata-put "ARKZ" "Fuso" *ArkZ_Fuso*)
       (vlax-ldata-put "ARKZ" "Meridiano" *ArkZ_Meridiano*)
       
       (princ (strcat "\n? Zona salva no desenho: " *ArkZ_Fuso* " | " *ArkZ_Meridiano*))
     )
  )
  (princ)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:GetZoneFromARKZ - Lê a zona do dicionário ARKZ
;;;===========================================================================
(defun ArkZ:GetZoneFromARKZ ( / fuso meridiano)
  (vl-load-com)
  (setq fuso nil meridiano nil)
  
  (vl-catch-all-apply
    '(lambda ()
       (setq fuso (vlax-ldata-get "ARKZ" "Fuso" nil))
       (setq meridiano (vlax-ldata-get "ARKZ" "Meridiano" nil))
     )
  )
  
  (if (and fuso meridiano)
    (list fuso meridiano)
    nil
  )
)

;;;===========================================================================
;;; FUNÇÃO: format-azimuth
;;;===========================================================================
(defun format-azimuth (ang / d m s)
  (setq d (fix ang))
  (setq m (fix (* (- ang d) 60)))
  (setq s (fix (+ 0.5 (* (- (* (- ang d) 60) m) 60))))
  (if (= s 60) (setq s 0 m (1+ m)))
  (if (= m 60) (setq m 0 d (1+ d)))
  (strcat (itoa d) "°" (if (< m 10) (strcat "0" (itoa m)) (itoa m)) "'" (if (< s 10) (strcat "0" (itoa s)) (itoa s)) "\"")
)

;;;===========================================================================
;;; FUNÇÃO: SplitCSV - Divide string usando delimitador
;;;===========================================================================
(defun SplitCSV (str delim / result pos dlen)
  "Divide uma string usando o delimitador informado (ex: \",\", \";\", \"\\t\")"
  (if (null delim) (setq delim ";"))
  (setq dlen (strlen delim))
  (setq result '())
  
  (while (setq pos (vl-string-search delim str))
    (setq result (append result (list (substr str 1 pos))))
    (setq str (substr str (+ pos 1 dlen)))
  )
  (if (> (strlen str) 0)
    (setq result (append result (list str)))
    (setq result (append result (list "")))
  )
  result
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ_ExecuteCSVDialog
;;;===========================================================================
(defun ArkZ_ExecuteCSVDialog ( / sub_id csv_status list_seps list_cols current_sep 
                                 raw_lines parsed_points file_handle line_str split_char 
                                 idx_x idx_y parsed_line coord_x coord_y)
  (setq sub_id (load_dialog "ArkZMemorialDescritivo.dcl"))
  (if (not (new_dialog "ArkZLineCSV" sub_id)) (exit))

  (setq list_seps (list "Vírgula (,)" "Ponto e Vírgula (;)" "Tabulação (Tab)"))
  (setq list_cols (list "Col 1" "Col 2" "Col 3" "Col 4" "Col 5"))

  (start_list "csv_sep")  (foreach item list_seps (add_list item)) (end_list)
  (start_list "col_x")    (foreach item list_cols (add_list item)) (end_list)
  (start_list "col_y")    (foreach item list_cols (add_list item)) (end_list)

  (set_tile "csv_path"    *ArkZ_CsvPath*)
  (set_tile "csv_sep"     *ArkZ_CsvSep*)
  (set_tile "csv_skip"    *ArkZ_CsvSkip*)
  (set_tile "col_x"       *ArkZ_ColX*)
  (set_tile "col_y"       *ArkZ_ColY*)
  
  (if (= *ArkZ_CsvPath* "") (mode_tile "csv_accept" 1))

  (defun AtualizarPainelCSV ( / file_handle line_str count text_preview split_char split_sample num_cols column_labels idx)
    (setq text_preview nil raw_lines nil)
    (if (and *ArkZ_CsvPath* (/= *ArkZ_CsvPath* ""))
      (progn
        (setq file_handle (open *ArkZ_CsvPath* "r") count 0)
        (if file_handle
          (progn
            (while (and (setq line_str (read-line file_handle)) (< count 5))
              (setq raw_lines (append raw_lines (list line_str)))
              (setq text_preview (append text_preview (list line_str)))
              (setq count (1+ count))
            )
            (close file_handle)
            
            (start_list "csv_preview")
            (foreach line text_preview (add_list line))
            (end_list)

            (setq split_char (cond ((= (get_tile "csv_sep") "0") ",") ((= (get_tile "csv_sep") "1") ";") (t "\t")))
            
            (if (car raw_lines)
              (progn
                (setq split_sample (SplitCSV (car raw_lines) split_char))
                (setq num_cols (length split_sample))
                (setq column_labels nil idx 1)
                (repeat num_cols
                  (setq column_labels (append column_labels (list (strcat "Coluna " (itoa idx)))))
                  (setq idx (1+ idx))
                )
                (start_list "col_x") (foreach col column_labels (add_list col)) (end_list)
                (start_list "col_y") (foreach col column_labels (add_list col)) (end_list)
                
                (if (>= (atoi (get_tile "col_x")) num_cols) (set_tile "col_x" "0"))
                (if (>= (atoi (get_tile "col_y")) num_cols) (set_tile "col_y" "1"))
              )
            )
            (mode_tile "csv_accept" 0)
          )
        )
      )
    )
  )

  (AtualizarPainelCSV)

  (action_tile "btn_browse"
    (strcat
      "(setq tmp_path (getfiled \"Selecionar planilha de pontos\" \"\" \"csv;txt\" 0))"
      "(if tmp_path (progn (setq *ArkZ_CsvPath* tmp_path) (set_tile \"csv_path\" *ArkZ_CsvPath*) (AtualizarPainelCSV)))"
    )
  )
  
  (action_tile "btn_detect_c3d"
    "(setq res_c3d (ArkZ:GetCivil3DZone))
     (if res_c3d
       (progn
         (setq *ArkZ_Fuso* (car res_c3d)
               *ArkZ_Meridiano* (cadr res_c3d))
         (set_tile \"txt_fuso_display\" *ArkZ_Fuso*)
         (set_tile \"txt_meridiano_display\" *ArkZ_Meridiano*)
       )
       (alert \"Nenhum sistema de coordenadas UTM ativo foi encontrado nas configuracoes do Civil 3D.\")
     )"
  )

  (action_tile "csv_sep" "(setq *ArkZ_CsvSep* $value) (AtualizarPainelCSV)")
  (action_tile "csv_skip" "(setq *ArkZ_CsvSkip* $value)")
  (action_tile "col_x" "(setq *ArkZ_ColX* $value)")
  (action_tile "col_y" "(setq *ArkZ_ColY* $value)")
  
  (action_tile "csv_accept" 
    "(setq *ArkZ_CsvSep*  (get_tile \"csv_sep\")
           *ArkZ_CsvSkip* (get_tile \"csv_skip\")
           *ArkZ_ColX*    (get_tile \"col_x\")
           *ArkZ_ColY*    (get_tile \"col_y\")) (done_dialog 1)"
  )
  (action_tile "csv_cancel" "(done_dialog 0)")

  (setq csv_status (start_dialog))
  (unload_dialog sub_id)

  (cond
    ((= csv_status 1)
     (progn
       (setq file_handle (open *ArkZ_CsvPath* "r")
             parsed_points nil
             split_char (cond ((= *ArkZ_CsvSep* "0") ",") ((= *ArkZ_CsvSep* "1") ";") (t "\t"))
             idx_x (atoi *ArkZ_ColX*)
             idx_y (atoi *ArkZ_ColY*))
       
       (if file_handle
         (progn
           (if (= *ArkZ_CsvSkip* "1") (read-line file_handle))
           
           (while (setq line_str (read-line file_handle))
             (setq parsed_line (SplitCSV line_str split_char))
             
             (if (> (length parsed_line) (max idx_x idx_y))
               (progn
                 (setq val_x_str (vl-string-trim " \t\r\n" (nth idx_x parsed_line))
                       val_y_str (vl-string-trim " \t\r\n" (nth idx_y parsed_line)))
                 
                 (setq coord_x (distof val_x_str 2)
                       coord_y (distof val_y_str 2))
                 
                 (if (and coord_x coord_y
                          (not (and (= coord_x 0.0) (= coord_y 0.0))))
                   (setq parsed_points (append parsed_points (list (list coord_x coord_y 0.0))))
                 )
               )
             )
           )
           (close file_handle)
         )
       )
       parsed_points
     )
    )
    (t nil)
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:GetStateName
;;;===========================================================================
(defun ArkZ:GetStateName (code / state_names)
  (setq state_names '(
    ("11" "Rondônia")
    ("12" "Acre")
    ("13" "Amazonas")
    ("14" "Roraima")
    ("15" "Pará")
    ("16" "Amapá")
    ("17" "Tocantins")
    ("21" "Maranhão")
    ("22" "Piauí")
    ("23" "Ceará")
    ("24" "Rio Grande do Norte")
    ("25" "Paraíba")
    ("26" "Pernambuco")
    ("27" "Alagoas")
    ("28" "Sergipe")
    ("29" "Bahia")
    ("31" "Minas Gerais")
    ("32" "Espírito Santo")
    ("33" "Rio de Janeiro")
    ("35" "São Paulo")
    ("41" "Paraná")
    ("42" "Santa Catarina")
    ("43" "Rio Grande do Sul")
    ("50" "Mato Grosso do Sul")
    ("51" "Mato Grosso")
    ("52" "Goiás")
    ("53" "Distrito Federal")
  ))
  
  (if (setq found (assoc code state_names))
    (cadr found)
    "Estado Desconhecido"
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:CalcularFusoPorLongitude (COM HEMISFÉRIO)
;;;===========================================================================
(defun ArkZ:CalcularFusoPorLongitude (longitude latitude / lon fuso lon_abs mc mc_deg mc_min meridiano hemis)
  "Calcula o fuso UTM e o Meridiano Central usando a fórmula matemática padrão"
  
  (if (= (type longitude) 'STR)
    (setq longitude (ArkZ:StrToReal longitude))
  )
  (if (= (type latitude) 'STR)
    (setq latitude (ArkZ:StrToReal latitude))
  )

  (setq lon (float longitude))
  (setq fuso (fix (/ (+ lon 180.0) 6.0)))
  (setq fuso (1+ fuso))
  
  (if (and latitude (> latitude 0))
    (setq hemis "N")
    (setq hemis "S")
  )

  (setq mc (- (* fuso 6) 183))

  (setq lon_abs (abs mc))
  (setq mc_deg (fix lon_abs))
  (setq mc_min (fix (* (- lon_abs mc_deg) 60.0)))
  
  (if (< mc_min 10)
    (setq meridiano (strcat (itoa mc_deg) "°0" (itoa mc_min) "' " 
                           (if (< mc 0) "W" "E")))
    (setq meridiano (strcat (itoa mc_deg) "°" (itoa mc_min) "' " 
                           (if (< mc 0) "W" "E")))
  )

  (list (strcat "Fuso " (itoa fuso) hemis) meridiano)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:NormalizarParaOrdenacao
;;; Versão mais robusta usando vl-string-translate
;;;===========================================================================
(defun ArkZ:NormalizarParaOrdenacao (str)
  (if (null str) (setq str ""))
  (vl-string-translate 
    "ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ" 
    "AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn" 
    str
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:CarregarCidades
;;;===========================================================================
(defun ArkZ:CarregarCidades ( / file line data cities states state_code)
  "Carrega cidades do arquivo CSV"
  (setq cities nil
        states nil)
  
  (if (setq file (findfile "ArkZMemorialDescritivo.csv"))
    (progn
      (setq file (open file "r"))
      (setq line (read-line file))
      
      (while (setq line (read-line file))
        (if (and line (> (strlen line) 0))
          (progn
            (setq data (SplitCSV line ";"))
            (if (>= (length data) 4)
              (progn
                (setq city_data (list (nth 0 data) (nth 1 data) (nth 2 data) (nth 3 data)))
                (setq cities (append cities (list city_data)))
                
                (setq state_code (substr (nth 0 data) 1 2))
                (if (null (assoc state_code states))
                  (setq states (append states (list (list state_code (ArkZ:GetStateName state_code)))))
                )
              )
            )
          )
        )
      )
      (close file)
      (setq states (vl-sort states '(lambda (a b) 
        (< (ArkZ:NormalizarParaOrdenacao (cadr a)) (ArkZ:NormalizarParaOrdenacao (cadr b)))))
      )
    )
  )
  (list states cities)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:SelectCity (COM HEMISFÉRIO)
;;;===========================================================================
(defun ArkZ:SelectCity ( / dcl_id states cities filtered_cities 
                          selected_state_idx selected_city_idx
                          city_data id city latitude longitude fuso_info
                          result *Filtered_Cities* *Selected_City*
                          loaded_data lon_num lat_num)

  (setq *Filtered_Cities* nil
        *Selected_City* nil
        states nil
        cities nil)
  
  (setq loaded_data (ArkZ:CarregarCidades))
  (setq states (car loaded_data))
  (setq cities (cadr loaded_data))
  
  (if (or (null states) (null cities))
    (progn
      (alert "Erro ao carregar dados do arquivo ArkZMemorialDescritivo.csv!\nVerifique se o arquivo existe e está no formato correto.")
      (exit)
    )
  )
  
  (setq dcl_id (load_dialog "ArkZMemorialDescritivo.dcl"))
  (if (not (new_dialog "SelectCity" dcl_id))
    (progn
      (alert "Erro ao carregar o diálogo SelectCity!\nVerifique o arquivo ArkZMemorialDescritivo.dcl.")
      (unload_dialog dcl_id)
      (exit)
    )
  )
  
  (start_list "state_list")
  (foreach state states
    (add_list (cadr state))
  )
  (end_list)
  
  (start_list "city_list")
  (add_list "Selecione um estado primeiro")
  (end_list)
  
  (set_tile "id" "")
  (set_tile "city" "")
  (set_tile "latitude" "")
  (set_tile "longitude" "")
  (set_tile "txt_fuso" "Aguardando seleção...")
  (set_tile "txt_meridiano" "Aguardando seleção...")
  
  (action_tile "state_list" 
    "(setq selected_state_idx (atoi $value))
     (if (and selected_state_idx states (< selected_state_idx (length states)))
       (progn
         (setq state_code (car (nth selected_state_idx states)))
         (setq *Filtered_Cities* 
           (vl-remove-if-not
             '(lambda (city) (eq state_code (substr (car city) 1 2)))
             cities
           )
         )
         (setq *Filtered_Cities* (vl-sort *Filtered_Cities* '(lambda (a b) 
           (< (ArkZ:NormalizarParaOrdenacao (cadr a)) (ArkZ:NormalizarParaOrdenacao (cadr b)))))
         )
         (start_list \"city_list\")
         (foreach city *Filtered_Cities*
           (add_list (cadr city))
         )
         (end_list)
         (set_tile \"id\" \"\")
         (set_tile \"city\" \"\")
         (set_tile \"latitude\" \"\")
         (set_tile \"longitude\" \"\")
         (set_tile \"txt_fuso\" \"Selecione uma cidade\")
         (set_tile \"txt_meridiano\" \"Selecione uma cidade\")
         (setq *Selected_City* nil)
       )
     )"
  )
  
  (action_tile "city_list" 
    "(setq selected_city_idx (atoi $value))
     (if (and selected_city_idx *Filtered_Cities* (< selected_city_idx (length *Filtered_Cities*)))
       (progn
         (setq city_data (nth selected_city_idx *Filtered_Cities*))
         (setq id (car city_data)
               city (cadr city_data)
               latitude (caddr city_data)
               longitude (cadddr city_data))
         (setq *Selected_City* city_data)
         (set_tile \"id\" id)
         (set_tile \"city\" city)
         (set_tile \"latitude\" latitude)
         (set_tile \"longitude\" longitude)
         
         (setq lon_num (ArkZ:StrToReal longitude))
         (setq lat_num (ArkZ:StrToReal latitude))
         (setq fuso_info (ArkZ:CalcularFusoPorLongitude lon_num lat_num))
         
         (set_tile \"txt_fuso\" (car fuso_info))
         (set_tile \"txt_meridiano\" (cadr fuso_info))
       )
     )"
  )
  
  (action_tile "ok" "(done_dialog 1)")
  (action_tile "cancel" "(done_dialog 0)")
  
  (setq result (start_dialog))
  (unload_dialog dcl_id)
  
  (if (= result 1)
    (if *Selected_City*
      (progn
        (setq id (nth 0 *Selected_City*)
              city (nth 1 *Selected_City*)
              latitude (nth 2 *Selected_City*)
              longitude (nth 3 *Selected_City*))
        
        (setq lon_num (ArkZ:StrToReal longitude))
        (setq lat_num (ArkZ:StrToReal latitude))
        (setq fuso_info (ArkZ:CalcularFusoPorLongitude lon_num lat_num))
        
        (setq *ArkZ_Fuso* (car fuso_info))
        (setq *ArkZ_Meridiano* (cadr fuso_info))
        (setq *ArkZ_CityData* (list id city latitude longitude *ArkZ_Fuso* *ArkZ_Meridiano*))
        
        (alert (strcat
          "CIDADE SELECIONADA:\n\n"
          "Código: " id "\n"
          "Cidade: " city "\n"
          "Latitude: " latitude "\n"
          "Longitude: " longitude "\n\n"
          "=== FUSO UTM ===\n"
          "Fuso: " *ArkZ_Fuso* "\n"
          "Meridiano: " *ArkZ_Meridiano*
        ))
        *ArkZ_CityData*
      )
      nil
    )
    nil
  )
)

;;;===========================================================================
;;; COMANDO: SelectCity (para uso direto)
;;;===========================================================================
(defun c:SelectCity ()
  (ArkZ:SelectCity)
)

;;;===========================================================================
;;; FUNÇÃO: FormatNumberBR
;;;===========================================================================
(defun FormatNumberBR (val dec / val_str parts int_str dec_str len result i count ch)
  (cond
    ((null val) "")
    ((= (type val) 'STR)
     (setq val (ArkZ:StrToReal val))
     (FormatNumberBR val dec))
    ((or (= (type val) 'REAL) (= (type val) 'INT))
     (setq val_str (rtos (float val) 2 dec))
     (if (vl-string-search "." val_str)
       (progn
         (setq parts (read (strcat "(" (vl-string-translate "." " " val_str) ")")))
         (setq int_str (itoa (car parts)))
         (setq dec_str (rtos (- (float val) (fix val)) 2 dec))
         (if (vl-string-search "." dec_str)
           (setq dec_str (substr dec_str (+ 2 (vl-string-search "." dec_str))))
           (setq dec_str "00")
         )
       )
       (progn
         (setq int_str (itoa (fix val)))
         (setq dec_str "00")
       )
     )
     (while (< (strlen dec_str) dec)
       (setq dec_str (strcat dec_str "0"))
     )
     (if (> (strlen dec_str) dec)
       (setq dec_str (substr dec_str 1 dec))
     )
     (setq len (strlen int_str))
     (setq result "")
     (setq count 0)
     (setq i len)
     (while (> i 0)
       (setq ch (substr int_str i 1))
       (setq result (strcat ch result))
       (setq count (1+ count))
       (if (and (= (rem count 3) 0) (> i 1))
         (setq result (strcat "." result))
       )
       (setq i (1- i))
     )
     (if (> dec 0)
       (strcat result "," dec_str)
       result
     )
    )
    (t (vl-prin1-to-string val))
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:get-azimute
;;;===========================================================================
(defun ArkZ:get-azimute (p1 p2 / ang az)
  (setq ang (angle p1 p2))
  (setq az (- (/ pi 2.0) ang))
  (if (< az 0.0) (setq az (+ az (* 2.0 pi))))
  az
)

;;;===========================================================================
;;; FUNÇÃO: TGTEXTO
;;;===========================================================================
(defun TGTEXTO (ins_txt value_str a h_txt camada / nw_obj AcDoc Space)
  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq Space (if (= 1 (getvar "CVPORT")) (vla-get-PaperSpace AcDoc) (vla-get-ModelSpace AcDoc)))
  (setq nw_obj (vla-addMtext Space (vlax-3d-point (trans ins_txt 1 0)) 0.0 value_str))
  (mapcar 
    '(lambda (pr val) (vlax-put nw_obj pr val))
    (list 'AttachmentPoint 'Height 'DrawingDirection 'InsertionPoint 'StyleName 'Layer 'Rotation)
    (list 5 h_txt 5 ins_txt "TGDdim" camada (if (and (< a (* pi 0.5)) (> a (* pi 1.5))) (setq a (+ a pi)) a))
  )
  (entmod
    (append
      (vl-remove-if '(lambda (x) (or (member (car x) '(90 63 421 45)) (< 419 (car x) 440))) (entget (entlast)))
      (list '(90 . 1) '(63 . 41) '(421 . 16770196) '(45 . 1.5))
    )
  )
  (entupd (entlast))
)

;;;===========================================================================
;;; FUNÇÃO: CRIAR-TABELA-UTM (VERSÃO CORRIGIDA - COM R=)
;;;===========================================================================
(defun CRIAR-TABELA-UTM (pt tabela area_total h_texto camada nome_imovel dec_tab / 
                         *ms* myTable row total_rows num_cols total_items idx_item 
                         proximo_vtx text_area str_norte str_este str_dist val_raio)
  (vl-load-com)
  (setq *ms* (vla-get-modelspace (vla-get-activedocument (vlax-get-acad-object))))
  (setq total_items (length tabela))
  (setq total_rows (+ 4 total_items))
  (setq num_cols 7)
  
  (setq myTable (vla-AddTable *ms* (vlax-3d-point pt) total_rows num_cols (* h_texto 2.5) (* h_texto 12.0)))
  (vla-put-Layer myTable camada)
  
  (vl-catch-all-apply 'vla-put-RegenerateTableSuppressed (list myTable :vlax-true))
  
  (vla-SetRowHeight myTable 0 (* h_texto 2.5))
  (vla-SetRowHeight myTable 1 (* h_texto 2.0))
  (vla-SetRowHeight myTable 2 (* h_texto 1.8))
  
  (vla-put-TitleSuppressed myTable :vlax-false)
  (vla-put-HeaderSuppressed myTable :vlax-false)
  (vla-Update myTable)
  
  ;; Título
  (vla-SetCellAlignment myTable 0 0 5)
  (vla-SetTextHeight myTable 0 h_texto)
  (vla-SetText myTable 0 0 (strcase nome_imovel))
  (vl-catch-all-apply 'vla-MergeCells (list myTable 0 0 0 (1- num_cols)))
  
  ;; Quadro Resumo
  (vla-SetCellAlignment myTable 1 0 5)
  (vla-SetTextHeight myTable 1 h_texto)
  (vla-SetText myTable 1 0 "QUADRO RESUMO")
  (vl-catch-all-apply 'vla-MergeCells (list myTable 1 1 0 (1- num_cols)))
  
  ;; Cabeçalhos
  (vla-SetTextHeight myTable 2 h_texto)
  (vla-SetText myTable 2 0 "VÉRTICE")
  (vla-SetText myTable 2 1 "NORTE")
  (vla-SetText myTable 2 2 "ESTE")
  (vla-SetText myTable 2 3 "DE")
  (vla-SetText myTable 2 4 "PARA")
  (vla-SetText myTable 2 5 "AZIMUTE/RAIO")
  (vla-SetText myTable 2 6 "DISTÂNCIA (m)")
  
  (setq i 0)
  (while (< i total_rows)
    (vla-SetRowHeight myTable i (* h_texto 2.0))
    (setq i (1+ i))
  )
  
  (vla-SetRowHeight myTable 0 (* h_texto 2.5))
  (vla-SetRowHeight myTable 1 (* h_texto 2.0))
  (vla-SetRowHeight myTable 2 (* h_texto 1.8))
  
  (setq row 3)
  (setq idx_item 1)
  
  (foreach item tabela
    (vla-SetRowHeight myTable row (* h_texto 2.0))
    (vla-SetTextHeight myTable row h_texto)
    
    (vla-SetText myTable row 0 (strcat "V" (itoa idx_item)))
    
    (setq str_norte (FormatNumberBR (distof (nth 0 item)) dec_tab))
    (setq str_este  (FormatNumberBR (distof (nth 1 item)) dec_tab))
    (vla-SetText myTable row 1 (if str_norte str_norte (nth 0 item)))
    (vla-SetText myTable row 2 (if str_este str_este (nth 1 item)))
    
    (vla-SetText myTable row 3 (strcat "V" (itoa idx_item)))
    
    (if (= idx_item total_items)
      (setq proximo_vtx "V1")
      (setq proximo_vtx (strcat "V" (itoa (1+ idx_item))))
    )
    (vla-SetText myTable row 4 proximo_vtx)
    
    ;; CORREÇÃO: Mostrar "R=7,30m" para curvas
    (if (and (nth 4 item) (not (equal (nth 4 item) "-")))
      (progn
        (setq val_raio (abs (distof (nth 4 item))))
        (if val_raio
          ;; Formatar como "R=7,30m"
          (vla-SetText myTable row 5 (strcat "R=" (FormatNumberBR val_raio dec_tab) "m"))
          (vla-SetText myTable row 5 (vl-string-left-trim "-" (nth 4 item)))
        )
      )
      (vla-SetText myTable row 5 (nth 3 item))
    )
    
    (setq str_dist (FormatNumberBR (distof (nth 2 item)) dec_tab))
    (vla-SetText myTable row 6 (if str_dist str_dist (nth 2 item)))
    
    (setq row (1+ row))
    (setq idx_item (1+ idx_item))
  )
  
  ;; Área
  (vla-SetRowHeight myTable row (* h_texto 2.0))
  (vla-SetTextHeight myTable row h_texto)
  (vla-SetCellAlignment myTable row 0 5)
  
  (if (and area_total (> area_total 0))
    (setq text_area (strcat "ÁREA = " (FormatNumberBR area_total 2) "m²"))
    (setq text_area "ÁREA = 0,00m²")
  )
  
  (vla-SetText myTable row 0 text_area)
  (vl-catch-all-apply 'vla-MergeCells (list myTable row row 0 (1- num_cols)))
  
  (vl-catch-all-apply 'vla-put-RegenerateTableSuppressed (list myTable :vlax-false))
  (vla-Update myTable)
  
  (princ (strcat "\nTabela criada com sucesso (" (itoa num_cols) " colunas) na camada " camada "!"))
  (princ)
)

;;;===========================================================================
;;; FUNÇÃO: UpdateDCLFields
;;;===========================================================================
(defun UpdateDCLFields ()
  (if (= (get_tile "rad_mode") "mode_sel")
    (progn (mode_tile "grp_csv" 1) (set_tile "accept" "Selecionar"))
    (progn (mode_tile "grp_csv" 0) (set_tile "accept" "Importar CSV..."))
  )
)

;;;===========================================================================
;;; FUNÇÕES DO MEMORIAL DESCRITIVO
;;;===========================================================================
(defun data-extenso-br ( / mes-list d m y)
  (setq mes-list '("Janeiro" "Fevereiro" "Março" "Abril" "Maio" "Junho" 
                   "Julho" "Agosto" "Setembro" "Outubro" "Novembro" "Dezembro"))
  (setq d (menucmd "M=$(edtime,$(getvar,date),DD)"))
  (setq m (nth (1- (atoi (menucmd "M=$(edtime,$(getvar,date),M)"))) mes-list))
  (setq y (menucmd "M=$(edtime,$(getvar,date),YYYY)"))
  (strcat d " de " m " de " y)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:GerarTextoMemorial - VERSÃO SIMPLIFICADA E CORRIGIDA
;;;===========================================================================
(defun ArkZ:GerarTextoMemorial (tabela area_val nome_imovel municipio dec_tab_num / 
                                item str n_str e_str total_perimetro idx dist 
                                confrontante raio_val azimute_str)
  
  (setq total_perimetro 0.0)
  (setq idx 0)
  (setq str "")
  
  ;; Cabeçalho do memorial
  (setq str (strcat "DESCRIÇÃO DO IMÓVEL: " (strcase nome_imovel) "\\P\\P"))
  
  (setq str (strcat str 
    "================================================================================\\P"
    "MEMORIAL DESCRITIVO E GEORREFERENCIAMENTO DE IMÓVEL\\P"
    "================================================================================\\P\\P"
    "1. IDENTIFICAÇÃO DO IMÓVEL\\P"
    "   Nome: " (strcase nome_imovel) "\\P"
    "   Município: " municipio "\\P"
    "   Data: " (data-extenso-br) "\\P\\P"
    "2. SISTEMA DE REFERÊNCIA\\P"
    "   Sistema Geodésico Brasileiro - SIRGAS 2000\\P"
    "   Projeção: UTM (Universal Transversa de Mercator)\\P"
    "   Fuso: " *ArkZ_Fuso* "\\P"
    "   Meridiano Central: " *ArkZ_Meridiano* "\\P"
    "   Hemisfério: " (if (wcmatch *ArkZ_Fuso* "*N*") "Norte" "Sul") "\\P\\P"
    "3. DESCRIÇÃO PERIMETRAL\\P"
  ))
  
  ;; Processar cada item da tabela
  (foreach item tabela
    (setq n_str (FormatNumberBR (distof (nth 1 item)) dec_tab_num))
    (setq e_str (FormatNumberBR (distof (nth 2 item)) dec_tab_num))
    (setq dist (distof (nth 6 item)))
    (if dist (setq total_perimetro (+ total_perimetro dist)))
    
    (if (null n_str) (setq n_str (nth 1 item)))
    (if (null e_str) (setq e_str (nth 2 item)))
    
    (setq idx (1+ idx))
    
    ;; Verificar se é uma curva (verifica se existe um 7º elemento - raio)
    (setq raio_val nil)
    (if (>= (length item) 8)
      (progn
        (setq raio_val (distof (nth 7 item)))
        (if (and raio_val (> (abs raio_val) 0.001))
          (setq raio_val (abs raio_val))  ; <-- SEMPRE POSITIVO
          (setq raio_val nil)
        )
      )
    )
    
    ;; Azimute da curva (campo 5)
    (setq azimute_str (nth 5 item))
    
    (if (= idx 1)
      ;; Primeiro vértice: inicia a descrição
      (setq str (strcat str "   Inicia-se a descrição deste perímetro no vértice " (nth 0 item) 
                       ", de coordenadas N:" n_str "m e E:" e_str "m; "))
      (progn
        ;; Construir o confrontante
        (setq confrontante (strcat "CONFRONTANTE TRECHO " (nth 3 item) "-" (nth 4 item)))
        
        ;; Verificar se é uma curva (tem raio)
        (if raio_val
          ;; CURVA: mostra azimute, raio e distância
          (setq str (strcat str "\\P   deste, segue confrontando com " confrontante 
                           ", com azimute " azimute_str
                           ", raio " (FormatNumberBR raio_val 2) "m "
                           "e distância de " (nth 6 item) "m, "
                           "até o vértice " (nth 4 item) 
                           ", de coordenadas N:" n_str "m e E:" e_str "m; "))
          ;; RETA: mostra azimute e distância
          (setq str (strcat str "\\P   deste, segue confrontando com " confrontante 
                           ", com azimute " azimute_str 
                           " e distância de " (nth 6 item) "m, "
                           "até o vértice " (nth 4 item) 
                           ", de coordenadas N:" n_str "m e E:" e_str "m; "))
        )
      )
    )
  )
  
  ;; Fechamento e rodapé
  (setq str (strcat str "\\P   Retornando ao vértice " (nth 0 (car tabela)) 
                   ", ponto inicial da descrição deste perímetro.\\P\\P"
                   "4. ÁREA E PERÍMETRO\\P"
                   "   Área Total: " (FormatNumberBR area_val 2) " m²\\P"
                   "   Perímetro Total: " (FormatNumberBR total_perimetro 2) " m\\P\\P"
                   "5. OBSERVAÇÕES\\P"
                   "   Esta descrição é parte integrante do processo de georreferenciamento.\\P"
                   "   Todos os azimutes, distâncias e áreas foram calculados no plano UTM.\\P"
                   "   A planilha de coordenadas anexa é parte integrante deste memorial.\\P\\P"
                   "6. RESPONSÁVEIS\\P"
                   "   Proprietário: ______________________________________\\P"
                   "   CPF/CNPJ: ______________________________________\\P"
                   "   Responsável Técnico: _______________________________\\P"
                   "   CREA/CAU: ______________________________________\\P"
                   "   Data: " (data-extenso-br) "\\P\\P"
                   "7. ANUÊNCIAS\\P"
                   "   Prefeitura Municipal: ______________________________\\P"
                   "   INCRA (se aplicável): ______________________________\\P"
                   "   Órgão Ambiental: ______________________________\\P"
                   "   Cartório de Registro de Imóveis: ___________________\\P\\P"
                   "================================================================================\\P"
                   "Documento gerado pelo sistema ArkZMemorialDescritivo v2.3\\P"
                   "================================================================================"
  ))
  
  ;; Retornar a string
  str
)

(defun ArkZ:CriarMTextMemorial (AcDoc pt_ins str_texto h_texto camada largura / *ms* mtxt_obj)
  (setq *ms* (vla-get-modelspace AcDoc))
  (setq mtxt_obj (vla-AddMText *ms* (vlax-3d-point pt_ins) largura str_texto))
  (vla-put-Height mtxt_obj h_texto)
  (vla-put-Layer mtxt_obj camada)
  (vla-Update mtxt_obj)
)

(defun ArkZ:CriarArquivoTXT (filepath tabela area_val nome_imovel municipio dec_tab / file str_limpa)
  (setq file (open filepath "w"))
  (if file
    (progn
      (setq str_limpa (ArkZ:GerarTextoMemorial tabela area_val nome_imovel municipio dec_tab))
      (while (vl-string-search "\\P" str_limpa)
        (setq str_limpa (vl-string-subst "\n" "\\P" str_limpa))
      )
      (write-line str_limpa file)
      (close file)
      (princ (strcat "\nMemorial descritivo exportado em: " filepath))
    )
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:VerificarFecho - Verifica se a polilinha está fechada (CORRIGIDA)
;;;===========================================================================
(defun ArkZ:VerificarFecho (obj / startPt endPt isClosed)
  "Verifica se a polilinha está fechada. 
   Retorna T se fechada (Closed = Yes), nil se aberta."
  
  ;; Verificar a propriedade Closed da polilinha
  (if (vlax-property-available-p obj 'Closed)
    (progn
      (setq isClosed (vlax-get-property obj 'Closed))
      (if isClosed
        (progn
          (princ "\n  ? Polilinha está fechada (Closed = Yes)")
          T
        )
        (progn
          (princ "\n  ?? Polilinha está aberta (Closed = No)")
          nil
        )
      )
    )
    (progn
      ;; Fallback: verificar se os pontos coincidem
      (setq startPt (vlax-curve-getStartPoint obj))
      (setq endPt (vlax-curve-getEndPoint obj))
      (if (equal startPt endPt 0.001) T nil)
    )
  )
)
;;;===========================================================================
;;; FUNÇÃO: ArkZ:FecharPolilinha - Fecha uma polilinha aberta
;;;===========================================================================
(defun ArkZ:FecharPolilinha (obj / ename)
  "Fecha uma polilinha aberta. Retorna T se fechou, nil se já estava fechada."
  (setq ename (vlax-vla-object->ename obj))
  
  (if (not (ArkZ:VerificarFecho obj))
    (progn
      (vla-put-Closed obj :vlax-true)
      (vla-Update obj)
      (princ "\n  -> Polilinha fechada automaticamente")
      T
    )
    (progn
      (princ "\n  -> Polilinha já está fechada")
      nil
    )
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:CorrigirPolilinha - Corrige e fecha polilinha
;;;===========================================================================
(defun ArkZ:CorrigirPolilinha (obj / startPt endPt resp closeIt)
  "Corrige a polilinha: verifica se está fechada e oferece para fechar."
  (setq startPt (vlax-curve-getStartPoint obj))
  (setq endPt (vlax-curve-getEndPoint obj))
  
  (if (not (ArkZ:VerificarFecho obj))
    (progn
      (princ (strcat "\n?? Polilinha aberta detectada!"))
      (princ (strcat "\n   Vértice inicial: " (rtos (car startPt) 2 2) "," (rtos (cadr startPt) 2 2)))
      (princ (strcat "\n   Vértice final:   " (rtos (car endPt) 2 2) "," (rtos (cadr endPt) 2 2)))
      (princ "\n   Distância entre extremidades: " (rtos (distance startPt endPt) 2 3) " m")
      
      ;; Perguntar ao usuário o que fazer
      (initget "Sim Nao")
      (setq resp (getkword "\nDeseja fechar a polilinha automaticamente? [Sim/Nao] <Sim>: "))
      
      (if (or (null resp) (= resp "Sim"))
        (progn
          (ArkZ:FecharPolilinha obj)
          T
        )
        (progn
          (princ "\n  -> Polilinha mantida aberta (opção do usuário)")
          nil
        )
      )
    )
    (progn
      (princ "\n  ? Polilinha já está fechada")
      T
    )
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:VerificarFechoCSV
;;;===========================================================================
(defun ArkZ:VerificarFechoCSV (points / firstPt lastPt resp closedPoints)
  "Verifica se a lista de pontos do CSV está fechada. Retorna a lista corrigida."
  (if (>= (length points) 2)
    (progn
      (setq firstPt (car points))
      (setq lastPt (last points))
      (setq closedPoints points)
      
      (if (equal firstPt lastPt 0.001)
        (progn
          (princ "\n  ? A polilinha do CSV está fechada")
          closedPoints
        )
        (progn
          (princ (strcat "\n  ?? A polilinha do CSV NÃO está fechada!"))
          (princ (strcat "\n     Distância entre extremidades: " 
                         (rtos (distance firstPt lastPt) 2 3) " m"))
          
          (initget "Sim Nao")
          (setq resp (getkword "\n  Deseja fechar a polilinha? [Sim/Nao] <Sim>: "))
          
          (if (or (null resp) (equal resp "Sim") (equal resp "S"))
            (progn
              (setq closedPoints (append points (list firstPt)))
              (princ (strcat "\n  ? Polilinha do CSV fechada (adicionado vértice V" 
                             (itoa (length closedPoints)) ")"))
              closedPoints
            )
            (progn
              (princ "\n  -> Polilinha do CSV mantida aberta (opção do usuário)")
              points
            )
          )
        )
      )
    )
    points
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:GetBulgeInfo - Extrai informações de bulge de uma polilinha
;;;===========================================================================
(defun ArkZ:GetBulgeInfo (obj / pts bulges i result)
  "Extrai informações de bulges de uma LWPOLYLINE"
  (setq result nil)
  
  (if (and obj (vlax-property-available-p obj 'GetBulge))
    (progn
      (setq pts (vlax-get-property obj 'Coordinates))
      (setq bulges (vlax-get-property obj 'Bulges))
      (setq i 0)
      (repeat (length pts)
        (setq result (append result (list (vla-GetBulge obj i))))
        (setq i (1+ i))
      )
    )
  )
  result
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:ProcessarCSV - VERSÃO CORRIGIDA (NÃO CRIA POLILINHA)
;;;===========================================================================
(defun ArkZ:ProcessarCSV (points_list / AcDoc Space oldlay total_area table_data mem_data 
                          nb total_pts pt_start pt_end seg_len pt_medio 
                          pt_leader text_leader ml_obj table_pt mem_pt mem_text 
                          h_vtx_num h_azi_num h_tab_num dec_vtx_num dec_azi_num dec_tab_num
                          safearray obj azimute rad arc_angle tg_len seg_bulge
                          pt_vtx pt_cen alpha)
  "Processa pontos do CSV, gerando anotações, tabela e memorial com suporte a curvas"
  
  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object))
        Space (if (= 1 (getvar "CVPORT")) 
                 (vla-get-PaperSpace AcDoc) 
                 (vla-get-ModelSpace AcDoc))
        table_data nil
        mem_data nil
        total_area 0.0
        oldlay (getvar "clayer"))
  
  (setq h_vtx_num   (distof *ArkZ_HVtx*)
        h_azi_num   (distof *ArkZ_HAzi*)
        h_tab_num   (distof *ArkZ_HTab*)
        dec_vtx_num (atoi *ArkZ_DecVtx*)
        dec_azi_num (atoi *ArkZ_DecAzi*)
        dec_tab_num (atoi *ArkZ_DecTab*))
  
  (if (and points_list (>= (length points_list) 2))
    (progn
      (princ (strcat "\n  -> Processando " (itoa (length points_list)) " pontos do CSV"))
      
      ;; =============================================================
      ;; OBTER ÁREA DA POLILINHA (se existir)
      ;; =============================================================
      (if (and *ArkZ_PLineEnt* (entget *ArkZ_PLineEnt*))
        (progn
          (setq obj (vlax-ename->vla-object *ArkZ_PLineEnt*))
          (if (vlax-property-available-p obj 'Area)
            (setq total_area (vla-get-Area obj))
          )
          (princ (strcat "\n  -> Usando polilinha existente para área: " (rtos total_area 2 2) " m²"))
        )
        (progn
          ;; Calcular área pela fórmula do polígono
          (setq total_area 0.0)
          (setq n 0)
          (setq total_pts (length points_list))
          ;; Remover duplicata de fechamento para cálculo
          (setq pts_calc points_list)
          (if (equal (car points_list) (last points_list) 0.001)
            (setq pts_calc (reverse (cdr (reverse points_list))))
          )
          (setq total_pts (length pts_calc))
          (while (< n (1- total_pts))
            (setq p1 (nth n pts_calc)
                  p2 (nth (1+ n) pts_calc)
                  total_area (+ total_area (* (car p1) (cadr p2)) (* -1 (car p2) (cadr p1))))
            (setq n (1+ n))
          )
          (setq total_area (/ (abs total_area) 2.0))
          (princ (strcat "\n  -> Área calculada pela fórmula: " (rtos total_area 2 2) " m²"))
        )
      )
      
      ;; =============================================================
      ;; GERAR ANOTAÇÕES PARA CADA SEGMENTO
      ;; =============================================================
      (setq nb 0)
      (setq total_pts (length points_list))
      
      ;; Verificar se a polilinha está fechada
      (setq isClosed (equal (car points_list) (last points_list) 0.001))
      
      ;; Se estiver fechada, remover o último ponto para não duplicar
      (if isClosed
        (setq pts_process (reverse (cdr (reverse points_list))))
        (setq pts_process points_list)
      )
      (setq total_pts (length pts_process))
      
      (while (< nb total_pts)
        (setq pt_start (nth nb pts_process)
              pt_end (nth (rem (1+ nb) total_pts) pts_process)
              seg_len (distance pt_start pt_end)
              pt_medio (list (/ (+ (car pt_start) (car pt_end)) 2.0)
                            (/ (+ (cadr pt_start) (cadr pt_end)) 2.0)
                            0.0))
        
        ;; =============================================================
        ;; DETECTAR CURVA - Verifica bulge da polilinha (se existir)
        ;; =============================================================
        (setq rad nil arc_angle nil tg_len nil seg_bulge 0.0)
        
        ;; Se tiver a entidade da polilinha, verifica o bulge
        (if (and *ArkZ_PLineEnt* 
                 (entget *ArkZ_PLineEnt*)
                 (vlax-property-available-p (vlax-ename->vla-object *ArkZ_PLineEnt*) 'GetBulge)
                 (< nb (vla-get-NumberOfVertices (vlax-ename->vla-object *ArkZ_PLineEnt*))))
          (progn
            (setq obj (vlax-ename->vla-object *ArkZ_PLineEnt*))
            (setq seg_bulge (vla-GetBulge obj nb))
            (if (not (zerop seg_bulge))
              (progn
                ;; É uma curva! Calcular raio e ângulo
                (setq rad (/ seg_len (* 4.0 (atan seg_bulge))))
                (setq arc_angle (* 4.0 (atan seg_bulge)))
                (setq tg_len (abs (* rad (sin arc_angle))))
                
                ;; Calcular o ponto do vértice da curva
                (setq alpha (+ (angle pt_start pt_end) 
                               (- (* pi 0.5) (* 2.0 (atan seg_bulge)))))
                (setq pt_cen (polar pt_start alpha rad))
                (setq pt_vtx (polar pt_start (- alpha (* pi 0.5)) 
                                    (* rad (/ (sin (* 2.0 (atan seg_bulge))) 
                                              (cos (* 2.0 (atan seg_bulge)))))))
                
                ;; Desenvolvimento da curva (comprimento do arco)
                (setq seg_len (abs (* rad arc_angle)))
                
                (princ (strcat "\n  -> Curva detectada no segmento V" (itoa (1+ nb)) "-V" 
                               (itoa (if (= (1+ nb) total_pts) 1 (1+ (1+ nb)))) 
                               " | Raio: " (rtos rad 2 2) "m | Desenvolvimento: " (rtos seg_len 2 2) "m"))
              )
            )
          )
        )
        
        ;; Calcular azimute
        (setq azimute (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)))
        
        ;; =============================================================
        ;; VÉRTICE (MLEADER)
        ;; =============================================================
        (if (= *ArkZ_TogVtx* "1")
          (progn
            (setq pt_leader (polar pt_start (+ (angle pt_start pt_end) (* pi 0.75)) (* h_vtx_num 4.0))
                  text_leader (strcat "VÉRTICE " (itoa (1+ nb)) "\\P" 
                            "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" 
                            "E: " (rtos (car pt_start) 2 dec_vtx_num)))
            (setvar "TEXTSIZE" h_vtx_num)
            (setq safearray (vlax-make-safearray vlax-vbDouble '(0 . 5)))
            (vlax-safearray-fill safearray (list (car pt_start) (cadr pt_start) 0.0
                                                 (car pt_leader) (cadr pt_leader) 0.0))
            (setq ml_obj (vla-AddMLeader Space (vlax-make-variant safearray) 0))
            (vla-put-Layer ml_obj *ArkZ_LayVtx*)
            (vla-put-TextString ml_obj text_leader)
            (vla-Update ml_obj)
          )
        )
        
        ;; =============================================================
        ;; TABELA - Com raio para curvas
        ;; =============================================================
        (if (and rad (not (zerop rad)))
          ;; Curva: coluna AZIMUTE/RAIO recebe o raio
          (setq table_data (append table_data (list (list 
              (rtos (cadr pt_start) 2 dec_tab_num)  ; NORTE
              (rtos (car pt_start) 2 dec_tab_num)   ; ESTE
              (rtos seg_len 2 dec_tab_num)          ; DISTÂNCIA (desenvolvimento)
              "-"                                   ; AZIMUTE/RAIO = "-"
              (rtos (abs rad) 2 dec_tab_num)        ; RAIO (positivo)
          ))))
          ;; Reta: mantém o azimute
          (setq table_data (append table_data (list (list 
              (rtos (cadr pt_start) 2 dec_tab_num)
              (rtos (car pt_start) 2 dec_tab_num)
              (rtos seg_len 2 dec_tab_num)
              azimute
              "-"
          ))))
        )
        
        ;; =============================================================
        ;; MEMORIAL - Com raio para curvas
        ;; =============================================================
        (if (and rad (not (zerop rad)))
          ;; Curva: inclui azimute, raio e desenvolvimento
          (setq mem_data (append mem_data (list (list
                (strcat "V" (itoa (1+ nb))) 
                (rtos (cadr pt_start) 2 dec_tab_num) 
                (rtos (car pt_start) 2 dec_tab_num)
                (strcat "V" (itoa (1+ nb))) 
                (strcat "V" (itoa (if (= (1+ nb) total_pts) 1 (+ 2 nb)))) 
                azimute                           ; AZIMUTE DA CURVA
                (rtos seg_len 2 dec_tab_num)      ; DESENVOLVIMENTO
                (rtos (abs rad) 2 dec_tab_num)    ; RAIO (positivo)
          ))))
          ;; Reta: usa azimute
          (setq mem_data (append mem_data (list (list
                (strcat "V" (itoa (1+ nb))) 
                (rtos (cadr pt_start) 2 dec_tab_num) 
                (rtos (car pt_start) 2 dec_tab_num)
                (strcat "V" (itoa (1+ nb))) 
                (strcat "V" (itoa (if (= (1+ nb) total_pts) 1 (+ 2 nb)))) 
                azimute
                (rtos seg_len 2 dec_tab_num)
                "0"
          ))))
        )

        ;; =============================================================
        ;; AZIMUTE NO DESENHO (TGTEXTO)
        ;; =============================================================
        (if (= *ArkZ_TogAzi* "1")
          (if (and rad (not (zerop rad)))
            ;; Curva: exibe informações detalhadas
            (progn
              (TGTEXTO pt_medio 
                (strcat "{\\fArial Narrow|b0|i0|c0|p34;Curva " (itoa (1+ nb)) 
                  "\\P AC:" (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                  "\\P TG:" (rtos (abs tg_len) 2 dec_azi_num) "m" 
                  "\\P Raio:" (rtos (abs rad) 2 dec_azi_num) "m" 
                  "\\P Distancia:" (rtos seg_len 2 dec_azi_num) "m}") 
                (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
            )
            ;; Reta: exibe distância e azimute
            (TGTEXTO pt_medio 
              (strcat "{\\fArial Narrow|b0|i0|c0|p34;Distancia " 
                      (rtos seg_len 2 dec_azi_num) "m\\P Azimute: " 
                      azimute "}") 
              (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
          )
        )
        
        (setq nb (1+ nb))
      )
      
      (princ (strcat "\n  -> Tabela: " (itoa (length table_data)) " linhas"))
      (princ (strcat "\n  -> Memorial: " (itoa (length mem_data)) " linhas"))
      
      ;; =============================================================
      ;; INSERIR TABELA
      ;; =============================================================
      (if (and (= *ArkZ_TogTab* "1") table_data)
        (progn
          (initget 1)
          (setq table_pt (getpoint "\nEspecifique o ponto para inserir a tabela: "))
          (if table_pt
            (CRIAR-TABELA-UTM table_pt table_data total_area 
                              h_tab_num *ArkZ_LayTab* 
                              *ArkZ_NomeLote* dec_tab_num)
          )
        )
      )
      
      ;; =============================================================
      ;; INSERIR MEMORIAL DESCRITIVO
      ;; =============================================================
      (if (and mem_data (> (length mem_data) 0))
        (progn
          (if (= *ArkZ_TogMemMText* "1")
            (progn
              (initget 1)
              (setq mem_pt (getpoint "\nEspecifique o ponto para inserir o MText do Memorial: "))
              (if mem_pt
                (progn
                  (setq mem_text (ArkZ:GerarTextoMemorial mem_data total_area 
                                  *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num))
                  (ArkZ:CriarMTextMemorial AcDoc mem_pt mem_text 
                    h_tab_num *ArkZ_LayTab* (* h_tab_num 80.0))
                  (princ "\n? Memorial Descritivo (MText) inserido com sucesso!")
                )
              )
            )
          )
          
          (if (= *ArkZ_TogMemTxt* "1")
            (progn
              (setq txt_path (getfiled "Salvar Memorial Descritivo" 
                               (strcat *ArkZ_NomeLote* ".txt") "txt" 1))
              (if txt_path
                (ArkZ:CriarArquivoTXT txt_path mem_data total_area 
                  *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num)
              )
            )
          )
        )
      )
      
      (setvar "clayer" oldlay)
      (princ "\n? Processamento CSV concluído!")
    )
    (alert "Lista de pontos inválida!")
  )
  (princ)
)

;;; FUNÇÃO: ArkZ:Processar (CORRIGIDA: Fechamento Polilinha/Tabela + Argumentos)
;;;===========================================================================
(defun ArkZ:Processar (status / AcDoc Space oldim oldlay a_base a_dir
                         h_vtx_num h_azi_num h_tab_num dec_vtx_num dec_azi_num dec_tab_num
                         table_data mem_data total_area txt_size_backup
                         js n ename obj pr nb typ_obj pt_start pt_end
                         pt_cen rad alpha pt_vtx dist_start dist_end
                         seg_len seg_bulge pt_medio pt_leader text_leader ml_obj
                         nw_style nw_font points_list pt_list lw_poly coordinates_array
                         table_pt mem_pt mem_text txt_path total_pts i)

  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object))
        Space (if (= 1 (getvar "CVPORT")) (vla-get-PaperSpace AcDoc) (vla-get-ModelSpace AcDoc))
        table_data nil
        mem_data nil
        total_area 0.0
        txt_size_backup (getvar "TEXTSIZE")
        js nil
        points_list nil)
  
  ;; Atribuição de variáveis numéricas
  (setq h_vtx_num   (distof *ArkZ_HVtx*)
        h_azi_num   (distof *ArkZ_HAzi*)
        h_tab_num   (distof *ArkZ_HTab*)
        dec_vtx_num (atoi *ArkZ_DecVtx*)
        dec_azi_num (atoi *ArkZ_DecAzi*)
        dec_tab_num (atoi *ArkZ_DecTab*))

  (if (null dec_tab_num) (setq dec_tab_num 2))
  (if (null dec_vtx_num) (setq dec_vtx_num 2))
  (if (null dec_azi_num) (setq dec_azi_num 2))

  (ArkZ:VerificarCamada (list *ArkZ_LayVtx* 2))
  (ArkZ:VerificarCamada (list *ArkZ_LayAzi* 7))
  (ArkZ:VerificarCamada (list *ArkZ_LayTab* 4))

  (if (null (tblsearch "STYLE" "TGDdim"))
    (progn
      (setq nw_style (vla-add (vla-get-textstyles AcDoc) "TGDdim")
            nw_font (strcat (getenv "systemroot") "\\Fonts\\Arial.ttf"))
      (mapcar '(lambda (pr val) (vlax-put-property nw_style pr val))
           (list 'FontFile 'Height 'ObliqueAngle 'Width 'TextGenerationFlag)
           (list nw_font 0.0 0.0 1.0 0.0))
    )
  )
  
  (setq oldim (getvar "dimzin") oldlay (getvar "clayer") a_base (getvar "ANGBASE") a_dir (getvar "ANGDIR"))
  (setvar "dimzin" 0) (setvar "ANGBASE" 0) (setvar "ANGDIR" 0)

  ;; =====================================================================
  ;; MODO 1: SELECIONAR POLILINHA EXISTENTE
  ;; =====================================================================
  (if (= *ArkZ_Mode* "mode_sel")
    (progn
      (princ "\nSelecione polilinhas/arcos: ")
      (setq js (ssget '((-4 . "<OR") 
                        (-4 . "<AND") (0 . "POLYLINE") (-4 . "<NOT") (-4 . "&") (70 . 126) (-4 . "NOT>") (-4 . "AND>") 
                        (0 . "LWPOLYLINE,ARC") 
                        (-4 . "OR>"))))
      
      (if js
        (progn
          (setq n -1)
          (repeat (sslength js)
            (setq ename (ssname js (setq n (1+ n))) 
                  obj (vlax-ename->vla-object ename))
            (if (vlax-property-available-p obj 'Area)
              (setq total_area (+ total_area (vla-get-Area obj)))
            )
          )
          
          (setq n -1)
          (repeat (sslength js)
            (setq ename (ssname js (setq n (1+ n))) 
                  obj (vlax-ename->vla-object ename) 
                  pr -1 
                  nb 0)
            (setq typ_obj (vla-get-ObjectName obj))
            
            ;; ARCO
            (if (eq typ_obj "AcDbArc")
              (progn 
                (setq pt_start (vlax-get obj 'StartPoint) 
                      pt_end (vlax-get obj 'EndPoint)
                      pt_cen (vlax-get obj 'Center) 
                      rad (vlax-get obj 'Radius)
                      alpha (* (vlax-get obj 'TotalAngle) 0.5) 
                      seg_len (vlax-get obj 'ArcLength)
                      pt_vtx (polar pt_cen (+ (vlax-get obj 'StartAngle) alpha) (* rad (/ (1- (cos alpha)) (cos alpha))))
                      nb (1+ nb)
                      pt_medio (mapcar '* (mapcar '+ pt_start pt_end) '(0.5 0.5 0.5)))
                
                (setq table_data (append table_data (list (list 
                    (rtos (cadr pt_start) 2 dec_tab_num)
                    (rtos (car pt_start) 2 dec_tab_num)
                    (rtos seg_len 2 dec_tab_num)
                    "-"
                    (rtos rad 2 dec_tab_num)
                ))))
                
                (setq mem_data (append mem_data (list (list
                      (strcat "V" (itoa nb)) 
                      (rtos (cadr pt_start) 2 dec_tab_num) 
                      (rtos (car pt_start) 2 dec_tab_num)
                      (strcat "V" (itoa nb)) 
                      (strcat "V" (itoa (1+ nb))) 
                      (rtos rad 2 dec_tab_num) 
                      (rtos seg_len 2 dec_tab_num)
                ))))

                (if (= *ArkZ_TogVtx* "1")
                  (progn
                    (setq pt_leader (polar pt_start (+ (angle pt_start pt_end) (* pi 0.75)) (* h_vtx_num 4.0))
                          text_leader (strcat "VÉRTICE " (itoa nb) "\\P" "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" "E: " (rtos (car pt_start) 2 dec_vtx_num)))
                    (setvar "TEXTSIZE" h_vtx_num)
                    (setq ml_obj (vla-AddMLeader Space (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble '(0 . 5)) (append pt_start pt_leader))) 0))
                    (vla-put-Layer ml_obj *ArkZ_LayVtx*)
                    (vla-put-TextString ml_obj text_leader)
                  )
                )
                
                (if (= *ArkZ_TogAzi* "1")
                  (TGTEXTO pt_medio 
                    (strcat "{\\fArial Narrow|b0|i0|c0|p34;Curva N+" (itoa nb) 
                      "\\P AC:" (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                      "\\P TG:" (rtos (distance pt_start pt_vtx) 2 dec_azi_num) "m" 
                      "\\P Raio:" (rtos rad 2 dec_azi_num) "m" 
                      "\\P Distancia:" (rtos seg_len 2 dec_azi_num) "m}") 
                    (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
                )
              )
              
              ;; POLILINHA / LWPOLYLINE
              (progn 
                (repeat (fix (vlax-curve-getEndParam obj))
                  (setq dist_start (vlax-curve-GetDistAtParam obj (setq pr (1+ pr))) 
                        dist_end (vlax-curve-GetDistAtParam obj (1+ pr))
                        pt_start (vlax-curve-GetPointAtParam obj pr) 
                        pt_end (vlax-curve-GetPointAtParam obj (1+ pr))
                        seg_len (- dist_end dist_start) 
                        seg_bulge (vla-GetBulge obj pr) 
                        nb (1+ nb)
                        pt_medio (vlax-curve-GetPointAtParam obj (+ 0.5 pr)))
                  
                  (if (= *ArkZ_TogVtx* "1")
                    (progn
                      (setq pt_leader (polar pt_start (+ (angle pt_start pt_end) (* pi 0.75)) (* h_vtx_num 4.0))
                            text_leader (strcat "VÉRTICE " (itoa nb) "\\P" "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" "E: " (rtos (car pt_start) 2 dec_vtx_num)))
                      (setvar "TEXTSIZE" h_vtx_num)
                      (setq ml_obj (vla-AddMLeader Space (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble '(0 . 5)) (append pt_start pt_leader))) 0))
                      (vla-put-Layer ml_obj *ArkZ_LayVtx*)
                      (vla-put-TextString ml_obj text_leader)
                    )
                  )
                  
                  (if (not (zerop seg_bulge))
                    (progn 
                      (setq rad (/ seg_len (* 4.0 (atan seg_bulge))) 
                            alpha (+ (angle pt_start pt_end) (- (* pi 0.5) (* 2.0 (atan seg_bulge))))
                            pt_cen (polar pt_start alpha rad) 
                            pt_vtx (polar pt_start (- alpha (* pi 0.5)) (* rad (/ (sin (* 2.0 (atan seg_bulge))) (cos (* 2.0 (atan seg_bulge))))))
                            alpha (if (< (* 2.0 (atan seg_bulge)) 0) (- pi (* 2.0 (atan seg_bulge))) (* 2.0 (atan seg_bulge))))
                      
                      (setq table_data (append table_data (list (list 
                          (rtos (cadr pt_start) 2 dec_tab_num)
                          (rtos (car pt_start) 2 dec_tab_num)
                          (rtos seg_len 2 dec_tab_num)
                          "-"
                          (rtos rad 2 dec_tab_num)
                      ))))
                      
                      (setq mem_data (append mem_data (list (list
                            (strcat "V" (itoa nb)) 
                            (rtos (cadr pt_start) 2 dec_tab_num) 
                            (rtos (car pt_start) 2 dec_tab_num)
                            (strcat "V" (itoa nb)) 
                            (strcat "V" (itoa (1+ nb))) 
                            (rtos rad 2 dec_tab_num) 
                            (rtos seg_len 2 dec_tab_num)
                      ))))
                      
                      (if (= *ArkZ_TogAzi* "1")
                        (TGTEXTO pt_medio 
                          (strcat "{\\fArial Narrow|b0|i0|c0|p34;Curva " (itoa nb) 
                            "\\P AC:" (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                            "\\P TG:" (rtos (distance pt_start pt_vtx) 2 dec_azi_num) "m" 
                            "\\P Raio:" (rtos rad 2 dec_azi_num) "m" 
                            "\\P Distancia:" (rtos seg_len 2 dec_azi_num) "m}") 
                          (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
                      )
                    )
                    (progn
                      (setq table_data (append table_data (list (list 
                          (rtos (cadr pt_start) 2 dec_tab_num)
                          (rtos (car pt_start) 2 dec_tab_num)
                          (rtos seg_len 2 dec_tab_num)
                          (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi))
                          "-"
                      ))))
                      
                      (setq mem_data (append mem_data (list (list
                            (strcat "V" (itoa nb)) 
                            (rtos (cadr pt_start) 2 dec_tab_num) 
                            (rtos (car pt_start) 2 dec_tab_num)
                            (strcat "V" (itoa nb)) 
                            (strcat "V" (itoa (1+ nb))) 
                            (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                            (rtos seg_len 2 dec_tab_num)
                      ))))
                      
                      (if (= *ArkZ_TogAzi* "1")
                        (TGTEXTO pt_medio 
                          (strcat "{\\fArial Narrow|b0|i0|c0|p34;Distancia " (rtos seg_len 2 dec_azi_num) "m\\P Azimute: " 
                            (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) "}") 
                          (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
                      )
                    )
                  )
                )
              )
            )
          )
        )
        (princ "\nNenhum objeto selecionado!")
      )
    )
    
    ;; =====================================================================
    ;; MODO 2: IMPORTAR CSV
    ;; =====================================================================
    (progn
      (setq points_list (ArkZ_ExecuteCSVDialog))
      (if (and points_list (>= (length points_list) 2))
        (progn
          (setq total_pts (length points_list))
          
          ;; Criar polilinha fechada
          (if (= *ArkZ_TogPoly* "1")
            (progn
              (setq pt_list (apply 'append (mapcar '(lambda (pt) (list (car pt) (cadr pt))) points_list)))
              (setq coordinates_array (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length pt_list)))))
              (vlax-safearray-fill coordinates_array pt_list)
              (setq lw_poly (vla-addLightWeightPolyline Space coordinates_array))
              (vla-put-Closed lw_poly :vlax-true) ; --- FECHA A POLILINHA ---
              (vla-put-Layer lw_poly oldlay)
              (if (vlax-property-available-p lw_poly 'Area)
                (setq total_area (vla-get-Area lw_poly))
              )
            )
          )
          
          (vla-ZoomExtents (vlax-get-acad-object))
          (vl-cmdf "_.zoom" "_extents")

          ;; Processar todos os vértices incluindo o segmento de FECHAMENTO (V_last -> V1)
          (setq i 0)
          (while (< i total_pts)
            (setq pt_start (nth i points_list)
                  pt_end   (nth (rem (1+ i) total_pts) points_list) ; no último ponto pega o 1º Ponto
                  seg_len  (distance pt_start pt_end)
                  pt_medio (mapcar '* (mapcar '+ pt_start pt_end) '(0.5 0.5 0.5)))

            ;; Vértice Leader
            (if (= *ArkZ_TogVtx* "1")
              (progn
                (setq pt_leader (polar pt_start (+ (angle pt_start pt_end) (* pi 0.75)) (* h_vtx_num 4.0))
                      text_leader (strcat "VÉRTICE " (itoa (1+ i)) "\\P" "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" "E: " (rtos (car pt_start) 2 dec_vtx_num)))
                (setvar "TEXTSIZE" h_vtx_num)
                (setq ml_obj (vla-AddMLeader Space (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble '(0 . 5)) (append pt_start pt_leader))) 0))
                (vla-put-Layer ml_obj *ArkZ_LayVtx*)
                (vla-put-TextString ml_obj text_leader)
              )
            )
            
            ;; Tabela
            (setq table_data (append table_data (list (list 
                (rtos (cadr pt_start) 2 dec_tab_num)
                (rtos (car pt_start) 2 dec_tab_num)
                (rtos seg_len 2 dec_tab_num)
                (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi))
                "-"
            ))))
            
            ;; Memorial (Trecho do último até o 1º é nomeado Vn -> V1)
            (setq mem_data (append mem_data (list (list
                  (strcat "V" (itoa (1+ i))) 
                  (rtos (cadr pt_start) 2 dec_tab_num) 
                  (rtos (car pt_start) 2 dec_tab_num)
                  (strcat "V" (itoa (1+ i))) 
                  (strcat "V" (itoa (if (= (1+ i) total_pts) 1 (1+ (1+ i))))) 
                  (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                  (rtos seg_len 2 dec_tab_num)
            ))))

            ;; Azimute
            (if (= *ArkZ_TogAzi* "1")
              (TGTEXTO pt_medio 
                (strcat "{\\fArial Narrow|b0|i0|c0|p34;Distancia " (rtos seg_len 2 dec_azi_num) "m\\P Azimute: " 
                  (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) "}") 
                (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
            )

            (setq i (1+ i))
          )
        )
      )
    )
  )

  ;; =====================================================================
  ;; INSERIR TABELA (CORRIGIDO: Passando os 7 argumentos)
  ;; =====================================================================
  (if (and (= *ArkZ_TogTab* "1") table_data)
    (progn
      (setq table_pt nil)
      (while (null table_pt)
        (setq table_pt (getpoint "\nClique na tela para definir o ponto de inserção da tabela: "))
      )
      ;; CORREÇÃO DO ERRO 'too few arguments': adicionado o argumento 'dec_tab_num' no final
      (CRIAR-TABELA-UTM table_pt table_data total_area h_tab_num *ArkZ_LayTab* *ArkZ_NomeLote* dec_tab_num)
    )
  )

  ;; =====================================================================
  ;; INSERIR MEMORIAL DESCRITIVO (CORRIGIDO)
  ;; =====================================================================
  (if (and mem_data (> (length mem_data) 0))
    (progn
      ;; Inserção em MText no AutoCAD
      (if (= *ArkZ_TogMemMText* "1")
        (progn
          (setq mem_pt (getpoint "\nEspecifique o ponto para inserir o MText do Memorial Descritivo: "))
          (if mem_pt
            (progn
              ;; CORREÇÃO: Adicionado 'dec_tab_num' como 5º argumento
              (setq mem_text (ArkZ:GerarTextoMemorial mem_data total_area *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num))
              (ArkZ:CriarMTextMemorial AcDoc mem_pt mem_text h_tab_num *ArkZ_LayTab* (* h_tab_num 80.0))
              (princ "\nMemorial Descritivo (MText) inserido no desenho com sucesso!")
            )
          )
        )
      )
      
      ;; Exportação em arquivo TXT
      (if (= *ArkZ_TogMemTxt* "1")
        (progn
          (setq txt_path (getfiled "Salvar Memorial Descritivo" (strcat *ArkZ_NomeLote* ".txt") "txt" 1))
          (if txt_path
            ;; CORREÇÃO: Adicionado 'dec_tab_num' como 5º argumento
            (ArkZ:CriarArquivoTXT txt_path mem_data total_area *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num)
          )
        )
      )
    )
  )
  
  ;; RESTAURAR VARIÁVEIS
  (setvar "clayer" oldlay) 
  (setvar "dimzin" oldim) 
  (setvar "TEXTSIZE" txt_size_backup)
  
  (princ "\nProcessamento concluído!")
  (princ)
)


;;;===========================================================================
;;; COMANDO: ArkZFecharCSV - Fecha polilinha a partir de pontos selecionados
;;;===========================================================================
(defun c:ArkZFecharCSV ( / ss i ename obj closedCount)
  (princ "\nSelecione as polilinhas para fechar: ")
  (setq ss (ssget '((0 . "LWPOLYLINE,POLYLINE"))))
  
  (if ss
    (progn
      (setq closedCount 0)
      (setq i 0)
      (repeat (sslength ss)
        (setq ename (ssname ss i)
              obj (vlax-ename->vla-object ename)
              i (1+ i))
        
        (if (ArkZ:FecharPolilinha obj)
          (setq closedCount (1+ closedCount))
        )
      )
      (princ (strcat "\n? " (itoa closedCount) " polilinhas fechadas!"))
    )
    (princ "\nNenhuma polilinha selecionada!")
  )
  (princ)
)

;;;===========================================================================
;;; COMANDO: ArkZFechar - Fecha polilinhas selecionadas
;;;===========================================================================
(defun c:ArkZFechar ( / js i ename obj count)
  (princ "\nSelecione as polilinhas para fechar: ")
  (setq js (ssget '((0 . "LWPOLYLINE,POLYLINE"))))
  
  (if js
    (progn
      (setq count 0)
      (setq i 0)
      (repeat (sslength js)
        (setq ename (ssname js i)
              obj (vlax-ename->vla-object ename)
              i (1+ i))
        
        (if (ArkZ:FecharPolilinha obj)
          (setq count (1+ count))
        )
      )
      (princ (strcat "\n? " (itoa count) " polilinhas fechadas com sucesso!"))
    )
    (princ "\nNenhuma polilinha selecionada!")
  )
  (princ)
)

;;;===========================================================================
;;; COMANDO: ArkZVerificar - Verifica fecho das polilinhas selecionadas
;;;===========================================================================
(defun c:ArkZVerificar ( / js i ename obj openList)
  (princ "\nSelecione as polilinhas para verificar: ")
  (setq js (ssget '((0 . "LWPOLYLINE,POLYLINE"))))
  
  (if js
    (progn
      (setq openList nil)
      (setq i 0)
      (repeat (sslength js)
        (setq ename (ssname js i)
              obj (vlax-ename->vla-object ename)
              i (1+ i))
        
        (if (not (ArkZ:VerificarFecho obj))
          (setq openList (append openList (list ename)))
        )
      )
      
      (if openList
        (progn
          (princ (strcat "\n?? " (itoa (length openList)) " polilinhas ABERTAS encontradas:"))
          (foreach ename openList
            (princ (strcat "\n   - " (vl-princ-to-string ename)))
          )
          (princ "\n\nUse o comando ARKZFECHAR para fechá-las.")
        )
        (princ "\n? Todas as polilinhas estão fechadas!")
      )
    )
    (princ "\nNenhuma polilinha selecionada!")
  )
  (princ)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:MainDialog (CORRIGIDA - RETORNA STATUS)
;;;===========================================================================
(defun ArkZ:MainDialog ( / dcl_id status city_data c3d_zone)
  (setq dcl_id (load_dialog "ArkZMemorialDescritivo.dcl"))
  (if (not (new_dialog "ArkZMemorialDescritivo" dcl_id)) (exit))

  ;; Tentar ler do dicionário ARKZ primeiro
  (setq savedZone (ArkZ:GetZoneFromARKZ))
  (if savedZone
    (progn
      (setq *ArkZ_Fuso* (car savedZone))
      (setq *ArkZ_Meridiano* (cadr savedZone))
    )
  )

  ;; Tentar detectar do Civil 3D
  (defun ArkZ:AtualizarCivil3DZone ()
    (setq c3d_zone (ArkZ:GetCivil3DZone))
    (if c3d_zone
      (progn
        (setq *ArkZ_Fuso*      (car c3d_zone)
              *ArkZ_Meridiano* (cadr c3d_zone))
        (set_tile "txt_fuso_display"      *ArkZ_Fuso*)
        (set_tile "txt_meridiano_display" *ArkZ_Meridiano*)
        t
      )
      nil
    )
  )

  ;; Se não tiver zona salva, tenta detectar
  (if (null savedZone)
    (ArkZ:AtualizarCivil3DZone)
  )

  ;; Preencher campos
  (set_tile "eb_nome_lote"   *ArkZ_NomeLote*)
  (set_tile "eb_municipio"   *ArkZ_Municip*)
  (set_tile "tg_mem_mtext"   *ArkZ_TogMemMText*)
  (set_tile "tg_mem_txt"     *ArkZ_TogMemTxt*)
  (set_tile "rad_mode"       *ArkZ_Mode*)
  (set_tile "tog_poly"       *ArkZ_TogPoly*)
  (set_tile "tog_vtx"        *ArkZ_TogVtx*)
  (set_tile "tog_azi"        *ArkZ_TogAzi*)
  (set_tile "tog_tab"        *ArkZ_TogTab*)
  (set_tile "lay_vtx"        *ArkZ_LayVtx*)
  (set_tile "lay_azi"        *ArkZ_LayAzi*)
  (set_tile "lay_tab"        *ArkZ_LayTab*)
  (set_tile "h_vtx"          *ArkZ_HVtx*)
  (set_tile "h_azi"          *ArkZ_HAzi*)
  (set_tile "h_tab"          *ArkZ_HTab*)
  (set_tile "dec_vtx"        *ArkZ_DecVtx*)
  (set_tile "dec_azi"        *ArkZ_DecAzi*)
  (set_tile "dec_tab"        *ArkZ_DecTab*)

  (set_tile "txt_fuso_display"      *ArkZ_Fuso*)
  (set_tile "txt_meridiano_display" *ArkZ_Meridiano*)

  (UpdateDCLFields)

  (defun ArkZ:SalvarEstadoTiles ()
    (setq *ArkZ_NomeLote*    (get_tile "eb_nome_lote")
          *ArkZ_Municip*     (get_tile "eb_municipio")
          *ArkZ_TogMemMText* (get_tile "tg_mem_mtext")
          *ArkZ_TogMemTxt*   (get_tile "tg_mem_txt")
          *ArkZ_Mode*        (get_tile "rad_mode")
          *ArkZ_TogPoly*     (get_tile "tog_poly")
          *ArkZ_TogVtx*      (get_tile "tog_vtx")
          *ArkZ_TogAzi*      (get_tile "tog_azi")
          *ArkZ_TogTab*      (get_tile "tog_tab")
          *ArkZ_LayVtx*      (strcase (get_tile "lay_vtx"))
          *ArkZ_LayAzi*      (strcase (get_tile "lay_azi"))
          *ArkZ_LayTab*      (strcase (get_tile "lay_tab"))
          *ArkZ_HVtx*        (get_tile "h_vtx")
          *ArkZ_HAzi*        (get_tile "h_azi")
          *ArkZ_HTab*        (get_tile "h_tab")
          *ArkZ_DecVtx*      (get_tile "dec_vtx")
          *ArkZ_DecAzi*      (get_tile "dec_azi")
          *ArkZ_DecTab*      (get_tile "dec_tab"))
  )
  
  ;; Ações dos botões
  (action_tile "btn_detect_c3d"
    "(if (not (ArkZ:AtualizarCivil3DZone))
       (alert \"Nenhum sistema de coordenadas UTM configurado nas definicoes do desenho do Civil 3D.\")
     )"
  )

  (action_tile "rad_mode" 
    "(setq *ArkZ_Mode* $value) (UpdateDCLFields)"
  )

  (action_tile "btn_select_city"
    "(setq city_data (ArkZ:SelectCity))
     (if city_data
       (progn
         (setq *ArkZ_Fuso* (nth 4 city_data))
         (setq *ArkZ_Meridiano* (nth 5 city_data))
         (setq *ArkZ_Municip* (strcat (nth 1 city_data) \", \" (ArkZ:GetStateName (substr (nth 0 city_data) 1 2))))
         (set_tile \"txt_fuso_display\" *ArkZ_Fuso*)
         (set_tile \"txt_meridiano_display\" *ArkZ_Meridiano*)
         (set_tile \"eb_municipio\" *ArkZ_Municip*)
         (c:ArkZSaveZone)
       )
     )"
  )

  ;; Botões que fecham o diálogo com status específico
  (action_tile "btn_vtx_avulso" "(ArkZ:SalvarEstadoTiles) (done_dialog 2)")
  (action_tile "btn_azi_avulso" "(ArkZ:SalvarEstadoTiles) (done_dialog 3)")
  
  ;; Botão "Selecionar" (para modo CSV ou Seleção)
  (action_tile "accept"         
    "(ArkZ:SalvarEstadoTiles) (done_dialog 1)"
  )
  
  (action_tile "help"   "(ArkZMemorialDescritivo_Help)")
  (action_tile "cancel" "(done_dialog 0)")

  (setq status (start_dialog))
  (unload_dialog dcl_id)
  status
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:CriarPolilinhaCSV - Usando entmake com números reais
;;;===========================================================================
(defun ArkZ:CriarPolilinhaCSV (points_list / pt_list ent)
  "Cria uma polilinha usando entmake - Trabalha diretamente com números reais"
  
  (if (and points_list (>= (length points_list) 2))
    (progn
      ;; Construir lista de pontos para entmake - FORMATO CORRETO
      (setq pt_list '())
      (foreach pt points_list
        ;; Garantir que são números reais (float)
        (setq x (float (car pt)))
        (setq y (float (cadr pt)))
        (setq pt_list (append pt_list (list (cons 10 (list x y 0.0)))))
      )
      
      ;; Criar a polilinha com entmake
      (entmake
        (append
          (list
            '(0 . "LWPOLYLINE")
            '(100 . "AcDbEntity")
            (cons 8 (getvar "clayer"))
            '(100 . "AcDbPolyline")
            (cons 90 (length pt_list))  ; Número de vértices
            (cons 70 (if (equal (car points_list) (last points_list) 0.001) 1 0)) ; Fechada
            '(38 . 0.0)  ; Elevação
          )
          pt_list
        )
      )
      
      ;; Retornar a entidade
      (setq ent (entlast))
      
      ;; Verificar se foi criada
      (if (and ent (= (cdr (assoc 0 (entget ent))) "LWPOLYLINE"))
        ent
        nil
      )
    )
    nil
  )
)



;;;===========================================================================
;;; COMANDO PRINCIPAL - VERSÃO CORRIGIDA COM RETORNO AO DCL
;;;===========================================================================
(defun c:ArkZMemorialDescritivo (/ dcl_id status sel resp points_list)
  (vl-load-com)
  
  ;; Salvar zona atual
  (c:ArkZSaveZone)
  
  ;; Carregar o DCL
  (setq dcl_id (load_dialog "ArkZMemorialDescritivo.dcl"))
  (if (not dcl_id)
    (progn
      (alert "Erro ao carregar o arquivo ArkZMemorialDescritivo.dcl!")
      (exit)
    )
  )
  
  ;; Loop principal do diálogo
  (setq status 1)
  (while (> status 0)
    (if (not (new_dialog "ArkZMemorialDescritivo" dcl_id))
      (exit)
    )
	
    (mode_tile "#arkz" 1)
    (MD_ShowSld "#img_logo" "ArkZMemorialDescritivo" "ArkZLogo" -2)
    (MD_ShowSld "sep1" "ArkZMemorialDescritivo" "Separato" -2)
    (MD_ShowSld "sep2" "ArkZMemorialDescritivo" "Separato" -2)

    ;; Preencher campos do DCL
    (set_tile "eb_nome_lote"   *ArkZ_NomeLote*)
    (set_tile "eb_municipio"   *ArkZ_Municip*)
    (set_tile "tg_mem_mtext"   *ArkZ_TogMemMText*)
    (set_tile "tg_mem_txt"     *ArkZ_TogMemTxt*)
    (set_tile "tog_poly"       *ArkZ_TogPoly*)
    (set_tile "tog_vtx"        *ArkZ_TogVtx*)
    (set_tile "tog_azi"        *ArkZ_TogAzi*)
    (set_tile "tog_tab"        *ArkZ_TogTab*)
    (set_tile "lay_vtx"        *ArkZ_LayVtx*)
    (set_tile "lay_azi"        *ArkZ_LayAzi*)
    (set_tile "lay_tab"        *ArkZ_LayTab*)
    (set_tile "h_vtx"          *ArkZ_HVtx*)
    (set_tile "h_azi"          *ArkZ_HAzi*)
    (set_tile "h_tab"          *ArkZ_HTab*)
    (set_tile "dec_vtx"        *ArkZ_DecVtx*)
    (set_tile "dec_azi"        *ArkZ_DecAzi*)
    (set_tile "dec_tab"        *ArkZ_DecTab*)
    (set_tile "txt_fuso_display"      *ArkZ_Fuso*)
    (set_tile "txt_meridiano_display" *ArkZ_Meridiano*)
    
    ;; Atualizar informações de navegação
    (if *ArkZ_PLinePts*
      (progn
        (set_tile "txt_total_vtx" (itoa (length *ArkZ_PLinePts*)))
        (set_tile "txt_v1_display" (itoa (1+ *ArkZ_StartVtxIdx*)))
      )
      (progn
        (set_tile "txt_total_vtx" "0")
        (set_tile "txt_v1_display" "-")
      )
    )
    
    (UpdateDCLFields)
    
    ;; =============================================================
    ;; AÇÕES DOS BOTÕES
    ;; =============================================================
    
    ;; BOTÃO: Selecionar Poligonal - APENAS SELECIONA
    (action_tile "mode_sel"
      "(setq *ArkZ_Mode* \"mode_sel\") (done_dialog 2)"
    )
    
    ;; BOTÃO: Importar CSV
    (action_tile "mode_csv"
      "(setq *ArkZ_Mode* \"mode_csv\") (done_dialog 3)"
    )
    
    ;; BOTÃO: Aplicar - PROCESSA A POLILINHA SELECIONADA
    (action_tile "btn_apply"
      "(setq *ArkZ_NomeLote*    (get_tile \"eb_nome_lote\")
             *ArkZ_Municip*     (get_tile \"eb_municipio\")
             *ArkZ_TogMemMText* (get_tile \"tg_mem_mtext\")
             *ArkZ_TogMemTxt*   (get_tile \"tg_mem_txt\")
             *ArkZ_TogPoly*     (get_tile \"tog_poly\")
             *ArkZ_TogVtx*      (get_tile \"tog_vtx\")
             *ArkZ_TogAzi*      (get_tile \"tog_azi\")
             *ArkZ_TogTab*      (get_tile \"tog_tab\")
             *ArkZ_LayVtx*      (strcase (get_tile \"lay_vtx\"))
             *ArkZ_LayAzi*      (strcase (get_tile \"lay_azi\"))
             *ArkZ_LayTab*      (strcase (get_tile \"lay_tab\"))
             *ArkZ_HVtx*        (get_tile \"h_vtx\")
             *ArkZ_HAzi*        (get_tile \"h_azi\")
             *ArkZ_HTab*        (get_tile \"h_tab\")
             *ArkZ_DecVtx*      (get_tile \"dec_vtx\")
             *ArkZ_DecAzi*      (get_tile \"dec_azi\")
             *ArkZ_DecTab*      (get_tile \"dec_tab\"))
       (done_dialog 4)"
    )
    
    ;; BOTÃO: Vértice Avulso
    (action_tile "btn_vtx_avulso"
      "(setq *ArkZ_LayVtx* (strcase (get_tile \"lay_vtx\"))
             *ArkZ_HVtx*   (get_tile \"h_vtx\")
             *ArkZ_DecVtx* (get_tile \"dec_vtx\")) (done_dialog 5)"
    )
    
    ;; BOTÃO: Azimute Avulso
    (action_tile "btn_azi_avulso"
      "(setq *ArkZ_LayAzi* (strcase (get_tile \"lay_azi\"))
             *ArkZ_HAzi*   (get_tile \"h_azi\")
             *ArkZ_DecAzi* (get_tile \"dec_azi\")) (done_dialog 6)"
    )
    
    ;; BOTÃO: Detectar Civil 3D
    (action_tile "btn_detect_c3d"
      "(setq c3d_zone (ArkZ:GetCivil3DZone))
       (if c3d_zone
         (progn
           (setq *ArkZ_Fuso* (car c3d_zone)
                 *ArkZ_Meridiano* (cadr c3d_zone))
           (set_tile \"txt_fuso_display\" *ArkZ_Fuso*)
           (set_tile \"txt_meridiano_display\" *ArkZ_Meridiano*)
         )
         (alert \"Nenhum sistema de coordenadas UTM ativo foi encontrado.\")
       )"
    )
    
    ;; BOTÃO: Selecionar Cidade
    (action_tile "btn_select_city"
      "(setq city_data (ArkZ:SelectCity))
       (if city_data
         (progn
           (setq *ArkZ_Fuso* (nth 4 city_data))
           (setq *ArkZ_Meridiano* (nth 5 city_data))
           (setq *ArkZ_Municip* (strcat (nth 1 city_data) \", \" (ArkZ:GetStateName (substr (nth 0 city_data) 1 2))))
           (set_tile \"txt_fuso_display\" *ArkZ_Fuso*)
           (set_tile \"txt_meridiano_display\" *ArkZ_Meridiano*)
           (set_tile \"eb_municipio\" *ArkZ_Municip*)
           (c:ArkZSaveZone)
         )
       )"
    )
    
    ;; BOTÃO: Navegar Vértices (Anterior)
    (action_tile "btn_prev_vtx"
      "(if *ArkZ_PLinePts*
         (progn
           (setq total (length *ArkZ_PLinePts*))
           (setq *ArkZ_StartVtxIdx* (rem (+ *ArkZ_StartVtxIdx* (1- total)) total))
           (ArkZ:DestacarVertice (nth *ArkZ_StartVtxIdx* *ArkZ_PLinePts*))
           (set_tile \"txt_v1_display\" (itoa (1+ *ArkZ_StartVtxIdx*)))
		   (ArkZ:AtualizarStatusSentido)
         )
         (alert \"Nenhuma polilinha selecionada!\")
       )"
    )
    
    ;; BOTÃO: Navegar Vértices (Próximo)
    (action_tile "btn_next_vtx"
      "(if *ArkZ_PLinePts*
         (progn
           (setq total (length *ArkZ_PLinePts*))
           (setq *ArkZ_StartVtxIdx* (rem (1+ *ArkZ_StartVtxIdx*) total))
           (ArkZ:DestacarVertice (nth *ArkZ_StartVtxIdx* *ArkZ_PLinePts*))
           (set_tile \"txt_v1_display\" (itoa (1+ *ArkZ_StartVtxIdx*)))
		   (ArkZ:AtualizarStatusSentido)
         )
         (alert \"Nenhuma polilinha selecionada!\")
       )"
    )
    
    ;; BOTÃO: Inverter Direção
    (action_tile "btn_invert_dir"
      "(if *ArkZ_PLinePts*
         (progn
           (if (= *ArkZ_InvertDir* \"0\")
             (setq *ArkZ_InvertDir* \"1\")
             (setq *ArkZ_InvertDir* \"0\")
           )
           (ArkZ:AtualizarStatusSentido)
           (princ (strcat \"\\nSentido invertido: \" (if (= *ArkZ_InvertDir* \"1\") \"Anti-horario\" \"Horario\")))
         )
         (alert \"Nenhuma polilinha selecionada!\")
       )"
    )
    
    ;; BOTÃO: Ajuda
    (action_tile "help" "(ArkZMemorialDescritivo_Help)")
    
    ;; BOTÃO: Fechar
    (action_tile "cancel" "(done_dialog 0)")
    
    (setq status (start_dialog))
    
    ;; =============================================================
    ;; PROCESSAR AÇÕES
    ;; =============================================================
    (cond
      ;; Ação 2: Selecionar Poligonal - APENAS SELECIONA E VOLTA AO DCL
      ((= status 2)
       (setq sel (car (entsel "\nSelecione a Polilinha desejada: ")))
       (if (and sel (= (cdr (assoc 0 (entget sel))) "LWPOLYLINE"))
         (progn
           (setq *ArkZ_PLineEnt* sel)
           (setq *ArkZ_PLinePts* 
                 (mapcar 'cdr (vl-remove-if-not '(lambda (x) (= (car x) 10)) (entget sel))))
           (setq *ArkZ_StartVtxIdx* 0)
           (setq *ArkZ_InvertDir* "0")
           (princ (strcat "\n? Polilinha selecionada com " 
                          (itoa (length *ArkZ_PLinePts*)) " vértices"))
           (princ "\nClique em 'Aplicar' para gerar as anotações.")
         )
         (alert "Objeto inválido! Selecione uma LWPOLYLINE.")
       )
      )

      ;; Ação 3: Importar CSV - CORRIGIDA (cria polilinha imediatamente)
      ((= status 3)
       (setq points_list (ArkZ_ExecuteCSVDialog))
       (if (and points_list (>= (length points_list) 2))
         (progn
           ;; Verificar fecho do CSV
           (setq points_list (ArkZ:VerificarFechoCSV points_list))
           (setq *ArkZ_PLinePts* points_list)
           
           ;; =============================================================
           ;; CRIAR POLILINHA IMEDIATAMENTE (para visualização durante navegação)
           ;; =============================================================
           (if (= *ArkZ_TogPoly* "1")
             (progn
               (princ "\n  -> Criando polilinha a partir dos pontos do CSV...")
               
               ;; Remover o ponto de fechamento duplicado se existir
               (setq pts_para_poly points_list)
               (if (equal (car points_list) (last points_list) 0.001)
                 (setq pts_para_poly (reverse (cdr (reverse points_list))))
               )
               
               ;; Criar a polilinha com entmake (ABERTA - será fechada com Closed=1)
               (setq pt_list '())
               (foreach pt pts_para_poly
                 (setq x (float (car pt)))
                 (setq y (float (cadr pt)))
                 (setq pt_list (append pt_list (list (cons 10 (list x y 0.0)))))
               )
               
               ;; Criar a polilinha com entmake (FECHADA)
               (entmake
                 (append
                   (list
                     '(0 . "LWPOLYLINE")
                     '(100 . "AcDbEntity")
                     (cons 8 (getvar "clayer"))
                     '(100 . "AcDbPolyline")
                     (cons 90 (length pt_list))
                     '(70 . 1)  ; FECHADA
                     '(38 . 0.0)
                   )
                   pt_list
                 )
               )
               
               (setq lw_poly (entlast))
               
               (if (and lw_poly (= (cdr (assoc 0 (entget lw_poly))) "LWPOLYLINE"))
                 (progn
                   (setq *ArkZ_PLineEnt* lw_poly)
                   (princ "\n  ? Polilinha criada com sucesso!")
                   
                   ;; Obter área
                   (setq obj (vlax-ename->vla-object lw_poly))
                   (if (vlax-property-available-p obj 'Area)
                     (princ (strcat "\n     Área: " (rtos (vla-get-Area obj) 2 2) " m²"))
                   )
                   
                   ;; Zoom
                   (vla-ZoomExtents (vlax-get-acad-object))
                   (vl-cmdf "_.zoom" "_extents")
                 )
                 (princ "\n  ?? Falha ao criar polilinha!")
               )
             )
             (princ "\n  -> Criação de polilinha desativada (opção não marcada)")
           )
           
           (princ (strcat "\n? CSV importado com " (itoa (length points_list)) " pontos."))
           (princ "\nClique em 'Aplicar' para gerar as anotações.")
         )
         (princ "\nNenhum ponto válido importado!")
       )
      )

      ;; Ação 4: Aplicar - PROCESSA A POLILINHA SELECIONADA
      ((= status 4)
       (if *ArkZ_PLinePts*
         (progn
           ;; Reordenar pontos conforme V1 e sentido
           (setq pts_ordenados (ArkZ:ReordenarPontos 
                                 *ArkZ_PLinePts* 
                                 *ArkZ_StartVtxIdx* 
                                 *ArkZ_InvertDir*))
           
           ;; Processar a polilinha
           (princ "\nProcessando polilinha selecionada...")
           (if *ArkZ_PLineEnt*
             ;; Usar a função de processamento da polilinha (com bulges)
             (ArkZ:ProcessarPolilinha)
             ;; Usar processamento CSV
             (ArkZ:ProcessarCSV pts_ordenados)
           )
           (setq status 0) ; Fecha o loop
         )
         (alert "Selecione uma Polilinha ou importe um CSV antes de aplicar!")
       )
      )
      
      ;; Ação 5: Vértice Avulso
      ((= status 5) (c:ArkZVtx))
      
      ;; Ação 6: Azimute Avulso
      ((= status 6) (c:ArkZAzi))
      
      ;; Ação 0: Fechar
      ((= status 0) (princ "\nOperação finalizada."))
    )
  )

  (unload_dialog dcl_id)
  (princ)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:ProcessarPolilinha - Processa a polilinha já selecionada
;;;===========================================================================
(defun ArkZ:ProcessarPolilinha ( / AcDoc Space oldim oldlay a_base a_dir
                         h_vtx_num h_azi_num h_tab_num dec_vtx_num dec_azi_num dec_tab_num
                         table_data mem_data total_area txt_size_backup
                         obj pr nb pt_start pt_end
                         pt_cen rad alpha pt_vtx dist_start dist_end
                         seg_len seg_bulge pt_medio pt_leader text_leader ml_obj
                         nw_style nw_font
                         table_pt mem_pt mem_text txt_path azimute_curva
                         ename)

  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object))
        Space (if (= 1 (getvar "CVPORT")) (vla-get-PaperSpace AcDoc) (vla-get-ModelSpace AcDoc))
        table_data nil
        mem_data nil
        total_area 0.0
        txt_size_backup (getvar "TEXTSIZE"))
  
  (setq h_vtx_num   (distof *ArkZ_HVtx*)
        h_azi_num   (distof *ArkZ_HAzi*)
        h_tab_num   (distof *ArkZ_HTab*)
        dec_vtx_num (atoi *ArkZ_DecVtx*)
        dec_azi_num (atoi *ArkZ_DecAzi*)
        dec_tab_num (atoi *ArkZ_DecTab*))

  (ArkZ:VerificarCamada (list *ArkZ_LayVtx* 2))
  (ArkZ:VerificarCamada (list *ArkZ_LayAzi* 7))
  (ArkZ:VerificarCamada (list *ArkZ_LayTab* 4))

  (if (null (tblsearch "STYLE" "TGDdim"))
    (progn
      (setq nw_style (vla-add (vla-get-textstyles AcDoc) "TGDdim")
            nw_font (strcat (getenv "systemroot") "\\Fonts\\Arial.ttf"))
      (mapcar '(lambda (pr val) (vlax-put-property nw_style pr val))
           (list 'FontFile 'Height 'ObliqueAngle 'Width 'TextGenerationFlag)
           (list nw_font 0.0 0.0 1.0 0.0))
    )
  )
  
  (setq oldim (getvar "dimzin") oldlay (getvar "clayer") a_base (getvar "ANGBASE") a_dir (getvar "ANGDIR"))
  (setvar "dimzin" 0) (setvar "ANGBASE" 0) (setvar "ANGDIR" 0)

  ;; =====================================================================
  ;; VERIFICAR SE EXISTE UMA POLILINHA SELECIONADA
  ;; =====================================================================
  (if (and *ArkZ_PLineEnt* (entget *ArkZ_PLineEnt*))
    (progn
      (setq ename *ArkZ_PLineEnt*
            obj (vlax-ename->vla-object ename)
            pr -1 
            nb 0)
      
      (princ (strcat "\n  -> Processando polilinha selecionada com " 
                     (itoa (length *ArkZ_PLinePts*)) " vértices"))
      
      ;; --- Calcular área ---
      (if (vlax-property-available-p obj 'Area)
        (setq total_area (vla-get-Area obj))
      )
      
      ;; --- Processar a polilinha ---
      (if (= (vla-get-ObjectName obj) "AcDbArc")
        (progn 
          (setq pt_start (vlax-get obj 'StartPoint) 
                pt_end (vlax-get obj 'EndPoint)
                pt_cen (vlax-get obj 'Center) 
                rad (vlax-get obj 'Radius)
                alpha (* (vlax-get obj 'TotalAngle) 0.5) 
                seg_len (vlax-get obj 'ArcLength)
                pt_vtx (polar pt_cen (+ (vlax-get obj 'StartAngle) alpha) (* rad (/ (1- (cos alpha)) (cos alpha))))
                nb (1+ nb)
                pt_medio (mapcar '* (mapcar '+ pt_start pt_end) '(0.5 0.5 0.5)))
          
          (setq azimute_curva (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)))
          
          (setq table_data (append table_data (list (list 
              (rtos (cadr pt_start) 2 dec_tab_num)
              (rtos (car pt_start) 2 dec_tab_num)
              (rtos seg_len 2 dec_tab_num)
              "-"
              (rtos (abs rad) 2 dec_tab_num)
          ))))
          
          (setq mem_data (append mem_data (list (list
                (strcat "V" (itoa nb)) 
                (rtos (cadr pt_start) 2 dec_tab_num) 
                (rtos (car pt_start) 2 dec_tab_num)
                (strcat "V" (itoa nb)) 
                (strcat "V" (itoa (1+ nb))) 
                azimute_curva
                (rtos seg_len 2 dec_tab_num)
                (rtos (abs rad) 2 dec_tab_num)
          ))))

          (if (= *ArkZ_TogVtx* "1")
            (progn
              (setq pt_leader (polar pt_start (+ (angle pt_start pt_end) (* pi 0.75)) (* h_vtx_num 4.0))
                    text_leader (strcat "VÉRTICE " (itoa nb) "\\P" "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" "E: " (rtos (car pt_start) 2 dec_vtx_num)))
              (setvar "TEXTSIZE" h_vtx_num)
              (setq ml_obj (vla-AddMLeader Space (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble '(0 . 5)) (append pt_start pt_leader))) 0))
              (vla-put-Layer ml_obj *ArkZ_LayVtx*)
              (vla-put-TextString ml_obj text_leader)
            )
          )
          
          (if (= *ArkZ_TogAzi* "1")
            (TGTEXTO pt_medio 
              (strcat "{\\fArial Narrow|b0|i0|c0|p34;Curva N+" (itoa nb) 
                "\\P AC:" (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                "\\P TG:" (rtos (distance pt_start pt_vtx) 2 dec_azi_num) "m" 
                "\\P Raio:" (rtos (abs rad) 2 dec_azi_num) "m" 
                "\\P Distancia:" (rtos seg_len 2 dec_azi_num) "m}") 
              (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
          )
        )
        
        ;; --- LWPOLYLINE ---
        (progn 
          (repeat (fix (vlax-curve-getEndParam obj))
            (setq dist_start (vlax-curve-GetDistAtParam obj (setq pr (1+ pr))) 
                  dist_end (vlax-curve-GetDistAtParam obj (1+ pr))
                  pt_start (vlax-curve-GetPointAtParam obj pr) 
                  pt_end (vlax-curve-GetPointAtParam obj (1+ pr))
                  seg_len (- dist_end dist_start) 
                  seg_bulge (vla-GetBulge obj pr) 
                  nb (1+ nb)
                  pt_medio (vlax-curve-GetPointAtParam obj (+ 0.5 pr)))
            
            (if (= *ArkZ_TogVtx* "1")
              (progn
                (setq pt_leader (polar pt_start (+ (angle pt_start pt_end) (* pi 0.75)) (* h_vtx_num 4.0))
                      text_leader (strcat "VÉRTICE " (itoa nb) "\\P" "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" "E: " (rtos (car pt_start) 2 dec_vtx_num)))
                (setvar "TEXTSIZE" h_vtx_num)
                (setq ml_obj (vla-AddMLeader Space (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble '(0 . 5)) (append pt_start pt_leader))) 0))
                (vla-put-Layer ml_obj *ArkZ_LayVtx*)
                (vla-put-TextString ml_obj text_leader)
              )
            )
            
            ;; --- CURVA ---
            (if (not (zerop seg_bulge))
              (progn 
                (setq rad (/ seg_len (* 4.0 (atan seg_bulge))) 
                      alpha (+ (angle pt_start pt_end) (- (* pi 0.5) (* 2.0 (atan seg_bulge))))
                      pt_cen (polar pt_start alpha rad) 
                      pt_vtx (polar pt_start (- alpha (* pi 0.5)) (* rad (/ (sin (* 2.0 (atan seg_bulge))) (cos (* 2.0 (atan seg_bulge))))))
                      alpha (if (< (* 2.0 (atan seg_bulge)) 0) (- pi (* 2.0 (atan seg_bulge))) (* 2.0 (atan seg_bulge))))
                
                (setq azimute_curva (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)))
                
                (setq table_data (append table_data (list (list 
                    (rtos (cadr pt_start) 2 dec_tab_num)
                    (rtos (car pt_start) 2 dec_tab_num)
                    (rtos seg_len 2 dec_tab_num)
                    "-"
                    (rtos (abs rad) 2 dec_tab_num)
                ))))
                
                (setq mem_data (append mem_data (list (list
                      (strcat "V" (itoa nb)) 
                      (rtos (cadr pt_start) 2 dec_tab_num) 
                      (rtos (car pt_start) 2 dec_tab_num)
                      (strcat "V" (itoa nb)) 
                      (strcat "V" (itoa (1+ nb))) 
                      azimute_curva
                      (rtos seg_len 2 dec_tab_num)
                      (rtos (abs rad) 2 dec_tab_num)
                ))))
                
                (if (= *ArkZ_TogAzi* "1")
                  (TGTEXTO pt_medio 
                    (strcat "{\\fArial Narrow|b0|i0|c0|p34;Curva " (itoa nb) 
                      "\\P AC:" (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                      "\\P TG:" (rtos (distance pt_start pt_vtx) 2 dec_azi_num) "m" 
                      "\\P Raio:" (rtos (abs rad) 2 dec_azi_num) "m" 
                      "\\P Distancia:" (rtos seg_len 2 dec_azi_num) "m}") 
                    (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
                )
              )
              
              ;; --- RETA ---
              (progn
                (setq table_data (append table_data (list (list 
                    (rtos (cadr pt_start) 2 dec_tab_num)
                    (rtos (car pt_start) 2 dec_tab_num)
                    (rtos seg_len 2 dec_tab_num)
                    (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi))
                    "-"
                ))))
                
                (setq mem_data (append mem_data (list (list
                      (strcat "V" (itoa nb)) 
                      (rtos (cadr pt_start) 2 dec_tab_num) 
                      (rtos (car pt_start) 2 dec_tab_num)
                      (strcat "V" (itoa nb)) 
                      (strcat "V" (itoa (1+ nb))) 
                      (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                      (rtos seg_len 2 dec_tab_num)
                      "0"
                ))))
                
                (if (= *ArkZ_TogAzi* "1")
                  (TGTEXTO pt_medio 
                    (strcat "{\\fArial Narrow|b0|i0|c0|p34;Distancia " (rtos seg_len 2 dec_azi_num) "m\\P Azimute: " 
                      (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) "}") 
                    (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
                )
              )
            )
          )
        )
      )
      
      ;; =====================================================================
      ;; INSERIR TABELA
      ;; =====================================================================
      (if (and (= *ArkZ_TogTab* "1") table_data)
        (progn
          (initget 1)
          (setq table_pt (getpoint "\nEspecifique o ponto para inserir a tabela: "))
          (if table_pt
            (CRIAR-TABELA-UTM table_pt table_data total_area h_tab_num *ArkZ_LayTab* *ArkZ_NomeLote* dec_tab_num)
          )
        )
      )

      ;; =====================================================================
      ;; INSERIR MEMORIAL DESCRITIVO
      ;; =====================================================================
      (if (and mem_data (> (length mem_data) 0))
        (progn
          (if (= *ArkZ_TogMemMText* "1")
            (progn
              (initget 1)
              (setq mem_pt (getpoint "\nEspecifique o ponto para inserir o MText do Memorial Descritivo: "))
              (if mem_pt
                (progn
                  (setq mem_text (ArkZ:GerarTextoMemorial mem_data total_area *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num))
                  (ArkZ:CriarMTextMemorial AcDoc mem_pt mem_text h_tab_num *ArkZ_LayTab* (* h_tab_num 80.0))
                  (princ "\nMemorial Descritivo (MText) inserido no desenho com sucesso!")
                )
              )
            )
          )
          (if (= *ArkZ_TogMemTxt* "1")
            (progn
              (setq txt_path (getfiled "Salvar Memorial Descritivo" (strcat *ArkZ_NomeLote* ".txt") "txt" 1))
              (if txt_path
                (ArkZ:CriarArquivoTXT txt_path mem_data total_area *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num)
              )
            )
          )
        )
      )
    )
    (princ "\nNenhuma polilinha selecionada! Use o botão 'Selecionar Poligonal' primeiro.")
  )
  
  ;; =====================================================================
  ;; RESTAURAR VARIÁVEIS
  ;; =====================================================================
  (setvar "clayer" oldlay) 
  (setvar "dimzin" oldim) 
  (setvar "TEXTSIZE" txt_size_backup)
  
  (princ "\nProcessamento concluído!")
  (princ)
)

;;;===========================================================================
;;; COMANDO: ArkZDebugBulge - Depura bulges da polilinha selecionada
;;;===========================================================================
(defun c:ArkZDebugBulge ( / sel ent obj n total bulges)
  "Depura os bulges da polilinha selecionada"
  (setq sel (car (entsel "\nSelecione uma LWPOLYLINE para depurar: ")))
  
  (if sel
    (progn
      (setq ent (entget sel))
      (if (= (cdr (assoc 0 ent)) "LWPOLYLINE")
        (progn
          (setq obj (vlax-ename->vla-object sel))
          (setq n (vla-get-NumberOfVertices obj))
          (setq bulges nil)
          
          (princ (strcat "\n=== DEPURAÇÃO DE BULGES ==="))
          (princ (strcat "\nNúmero de vértices: " (itoa n)))
          
          (setq i 0)
          (while (< i n)
            (setq bulge (vla-GetBulge obj i))
            (setq bulges (append bulges (list bulge)))
            (if (not (zerop bulge))
              (princ (strcat "\n  Vértice " (itoa i) ": BULGE = " (rtos bulge 2 4) " (CURVA)"))
              (princ (strcat "\n  Vértice " (itoa i) ": BULGE = 0 (RETA)"))
            )
            (setq i (1+ i))
          )
          
          (princ "\n\n=== RESUMO ===")
          (setq total 0)
          (foreach b bulges
            (if (not (zerop b)) (setq total (1+ total)))
          )
          (princ (strcat "\nTotal de curvas: " (itoa total)))
          (princ "\nUse este diagnóstico para verificar se a polilinha tem curvas.")
        )
        (alert "Selecione uma LWPOLYLINE!")
      )
    )
    (alert "Nenhuma entidade selecionada!")
  )
  (princ)
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:ProcessarComPontos - VERSÃO CORRIGIDA COM EXTRAÇÃO DE BULGES
;;;===========================================================================
(defun ArkZ:ProcessarComPontos (pts / AcDoc Space oldlay total_area table_data mem_data 
                                nb total_pts pt_start pt_end seg_len pt_medio 
                                pt_leader text_leader ml_obj
                                table_pt mem_pt mem_text azimute resp
                                h_vtx_num h_azi_num h_tab_num 
                                dec_vtx_num dec_azi_num dec_tab_num
                                obj isClosed firstPt lastPt
                                pt_start_3d pt_leader_3d safearray
                                seg_bulge rad arc_angle tg_len pt_vtx pt_cen alpha
                                pline_obj)
  "Processa uma lista de pontos, extraindo bulges da polilinha original"
  
  ;; Verificar se a lista de pontos é válida
  (if (or (null pts) (< (length pts) 2))
    (progn
      (alert "Lista de pontos inválida! Selecione uma polilinha ou importe dados CSV.")
      (exit)
    )
  )
  
  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object))
        Space (if (= 1 (getvar "CVPORT")) 
                 (vla-get-PaperSpace AcDoc) 
                 (vla-get-ModelSpace AcDoc))
        table_data nil
        mem_data nil
        total_area 0.0
        oldlay (getvar "clayer"))
  
  ;; Obter variáveis de configuração
  (setq h_vtx_num   (distof *ArkZ_HVtx*)
        h_azi_num   (distof *ArkZ_HAzi*)
        h_tab_num   (distof *ArkZ_HTab*)
        dec_vtx_num (atoi *ArkZ_DecVtx*)
        dec_azi_num (atoi *ArkZ_DecAzi*)
        dec_tab_num (atoi *ArkZ_DecTab*))
  
  (if (and pts (>= (length pts) 2))
    (progn
      (princ (strcat "\n  -> Processando " (itoa (length pts)) " vértices"))
      
      ;; =============================================================
      ;; OBTER OBJETO DA POLILINHA PARA EXTRAIR BULGES
      ;; =============================================================
      (setq pline_obj nil)
      (if *ArkZ_PLineEnt*
        (progn
          (setq pline_obj (vlax-ename->vla-object *ArkZ_PLineEnt*))
          (princ "\n  -> Usando polilinha selecionada para extrair bulges")
        )
        (princ "\n  -> Nenhuma polilinha selecionada - usando pontos apenas")
      )
      
      ;; =============================================================
      ;; VERIFICAR SE A POLILINHA ESTÁ FECHADA
      ;; =============================================================
      (setq isClosed nil)
      
      (if pline_obj
        (progn
          (if (vlax-property-available-p pline_obj 'Closed)
            (setq isClosed (vlax-get-property pline_obj 'Closed))
          )
        )
      )
      
      (if (null isClosed)
        (progn
          (setq firstPt (car pts))
          (setq lastPt (last pts))
          (setq isClosed (equal firstPt lastPt 0.001))
        )
      )
      
      (if isClosed
        (princ "\n  ? Polilinha está fechada (Closed = Yes)")
        (progn
          (setq firstPt (car pts))
          (setq lastPt (last pts))
          
          (princ (strcat "\n  ?? Polilinha NÃO está fechada!"))
          (princ (strcat "\n     Distância entre extremidades: " 
                         (rtos (distance firstPt lastPt) 2 3) " m"))
          
          (initget "Sim Nao")
          (setq resp (getkword "\n  Deseja fechar a polilinha? [Sim/Nao] <Sim>: "))
          (if (or (null resp) (equal resp "Sim") (equal resp "S"))
            (progn
              (setq pts (append pts (list firstPt)))
              (princ (strcat "\n  ? Polilinha fechada (adicionado vértice V" 
                             (itoa (length pts)) ")"))
            )
            (princ "\n  -> Polilinha mantida aberta (opção do usuário)")
          )
        )
      )
      
      ;; =============================================================
      ;; CALCULAR ÁREA
      ;; =============================================================
      (if pline_obj
        (progn
          (if (vlax-property-available-p pline_obj 'Area)
            (setq total_area (vla-get-Area pline_obj))
          )
        )
        (progn
          (setq total_area 0.0)
          (setq n 0)
          (setq total_pts (length pts))
          (while (< n (1- total_pts))
            (setq p1 (nth n pts)
                  p2 (nth (1+ n) pts)
                  total_area (+ total_area (* (car p1) (cadr p2)) (* -1 (car p2) (cadr p1))))
            (setq n (1+ n))
          )
          (setq total_area (/ (abs total_area) 2.0))
        )
      )
      
      ;; =============================================================
      ;; GERAR ANOTAÇÕES PARA CADA SEGMENTO
      ;; =============================================================
      (setq nb 0)
      (setq total_pts (length pts))
      
      (while (< nb total_pts)
        (setq pt_start (nth nb pts)
              pt_end (nth (rem (1+ nb) total_pts) pts)
              pt_medio (list (/ (+ (car pt_start) (car pt_end)) 2.0)
                            (/ (+ (cadr pt_start) (cadr pt_end)) 2.0)
                            0.0))
        
        ;; =============================================================
        ;; EXTRAIR BULGE DA POLILINHA ORIGINAL
        ;; =============================================================
        (setq seg_bulge 0.0
              rad nil
              arc_angle nil
              tg_len nil
              pt_vtx nil)
        
        (if pline_obj
          (progn
            ;; Verificar se o índice nb é válido
            (if (and (<= nb (1- (vla-get-NumberOfVertices pline_obj)))
                     (vlax-property-available-p pline_obj 'GetBulge))
              (progn
                (setq seg_bulge (vla-GetBulge pline_obj nb))
                
                ;; Se tiver bulge (curva), calcular os parâmetros
                (if (not (zerop seg_bulge))
                  (progn
                    ;; Distância em linha reta entre os pontos
                    (setq seg_len (distance pt_start pt_end))
                    
                    ;; Calcular raio e ângulo
                    (setq rad (/ seg_len (* 4.0 (atan seg_bulge))))
                    (setq arc_angle (* 4.0 (atan seg_bulge)))
                    (setq tg_len (abs (* rad (sin arc_angle))))
                    
                    ;; Calcular o ponto do vértice da curva
                    (setq alpha (+ (angle pt_start pt_end) 
                                   (- (* pi 0.5) (* 2.0 (atan seg_bulge)))))
                    (setq pt_cen (polar pt_start alpha rad))
                    (setq pt_vtx (polar pt_start (- alpha (* pi 0.5)) 
                                        (* rad (/ (sin (* 2.0 (atan seg_bulge))) 
                                                  (cos (* 2.0 (atan seg_bulge)))))))
                    
                    ;; Desenvolvimento da curva (comprimento do arco)
                    (setq seg_len (abs (* rad arc_angle)))
                    
                    (princ (strcat "\n  >>> CURVA DETECTADA: V" (itoa (1+ nb)) 
                                   "-V" (itoa (if (= (1+ nb) total_pts) 1 (1+ (1+ nb))))
                                   " | Raio: " (rtos rad 2 2) "m"
                                   " | Desenvolvimento: " (rtos seg_len 2 2) "m"
                                   " | Ângulo: " (rtos (/ (* arc_angle 180.0) pi) 2 2) "°"))
                  )
                )
              )
            )
          )
        )
        
        ;; Se não tiver bulge ou não for curva, usar distância em linha reta
        (if (null rad)
          (setq seg_len (distance pt_start pt_end))
        )
        
        ;; Calcular azimute
        (setq azimute (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)))
        
        ;; =============================================================
        ;; VÉRTICE - Usando MLEADER
        ;; =============================================================
        (if (= *ArkZ_TogVtx* "1")
          (progn
            (setq pt_leader (polar pt_start 
                                   (+ (angle pt_start pt_end) (* pi 0.75)) 
                                   (* h_vtx_num 4.0))
                  text_leader (strcat "VÉRTICE " (itoa (1+ nb)) "\\P" 
                            "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" 
                            "E: " (rtos (car pt_start) 2 dec_vtx_num)))
            
            (setvar "TEXTSIZE" h_vtx_num)
            
            (setq safearray (vlax-make-safearray vlax-vbDouble '(0 . 5)))
            (vlax-safearray-fill safearray (list (car pt_start) (cadr pt_start) 0.0
                                                 (car pt_leader) (cadr pt_leader) 0.0))
            
            (setq ml_obj (vla-AddMLeader Space (vlax-make-variant safearray) 0))
            (vla-put-Layer ml_obj *ArkZ_LayVtx*)
            (vla-put-TextString ml_obj text_leader)
            (vla-Update ml_obj)
          )
        )
        
        ;; =============================================================
        ;; TABELA - Com raio para curvas
        ;; =============================================================
        (if rad
          ;; Curva: coluna AZIMUTE/RAIO recebe o raio (negativo no original)
          (setq table_data (append table_data (list (list 
              (rtos (cadr pt_start) 2 dec_tab_num)  ; NORTE
              (rtos (car pt_start) 2 dec_tab_num)   ; ESTE
              (rtos seg_len 2 dec_tab_num)          ; DISTÂNCIA (desenvolvimento)
              "-"                                   ; AZIMUTE/RAIO = "-"
              (rtos (- (abs rad)) 2 dec_tab_num)    ; RAIO com sinal negativo
          ))))
          ;; Reta: mantém o azimute
          (setq table_data (append table_data (list (list 
              (rtos (cadr pt_start) 2 dec_tab_num)
              (rtos (car pt_start) 2 dec_tab_num)
              (rtos seg_len 2 dec_tab_num)
              azimute
              "-"
          ))))
        )
        
        ;; =============================================================
        ;; MEMORIAL - Com raio para curvas
        ;; =============================================================
        (if rad
          ;; Curva: inclui raio e desenvolvimento
          (setq mem_data (append mem_data (list (list
                (strcat "V" (itoa (1+ nb))) 
                (rtos (cadr pt_start) 2 dec_tab_num) 
                (rtos (car pt_start) 2 dec_tab_num)
                (strcat "V" (itoa (1+ nb))) 
                (strcat "V" (itoa (if (= (1+ nb) total_pts) 1 (+ 2 nb)))) 
                (rtos rad 2 dec_tab_num)            ; RAIO
                (rtos seg_len 2 dec_tab_num)        ; DESENVOLVIMENTO
          ))))
          ;; Reta: usa azimute
          (setq mem_data (append mem_data (list (list
                (strcat "V" (itoa (1+ nb))) 
                (rtos (cadr pt_start) 2 dec_tab_num) 
                (rtos (car pt_start) 2 dec_tab_num)
                (strcat "V" (itoa (1+ nb))) 
                (strcat "V" (itoa (if (= (1+ nb) total_pts) 1 (+ 2 nb)))) 
                azimute
                (rtos seg_len 2 dec_tab_num)
          ))))
        )

        ;; =============================================================
        ;; AZIMUTE NO DESENHO (TGTEXTO)
        ;; =============================================================
        (if (= *ArkZ_TogAzi* "1")
          (if rad
            ;; Curva: exibe informações detalhadas
            (progn
              (princ (strcat "\n  -> Inserindo texto de curva no segmento " (itoa (1+ nb))))
              (TGTEXTO pt_medio 
                (strcat "{\\fArial Narrow|b0|i0|c0|p34;Curva " (itoa (1+ nb)) 
                  "\\P AC:" (format-azimuth (/ (* (ArkZ:get-azimute pt_start pt_end) 180.0) pi)) 
                  "\\P TG:" (rtos (abs tg_len) 2 dec_azi_num) "m" 
                  "\\P Raio:" (rtos (abs rad) 2 dec_azi_num) "m" 
                  "\\P Distancia:" (rtos seg_len 2 dec_azi_num) "m}") 
                (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
            )
            ;; Reta: exibe distância e azimute
            (TGTEXTO pt_medio 
              (strcat "{\\fArial Narrow|b0|i0|c0|p34;Distancia " 
                      (rtos seg_len 2 dec_azi_num) "m\\P Azimute: " 
                      azimute "}") 
              (angle pt_start pt_end) h_azi_num *ArkZ_LayAzi*)
          )
        )
        
        (setq nb (1+ nb))
      )
      
      (princ (strcat "\n  -> Tabela: " (itoa (length table_data)) " linhas"))
      (princ (strcat "\n  -> Memorial: " (itoa (length mem_data)) " linhas"))
      
      ;; =============================================================
      ;; INSERIR TABELA
      ;; =============================================================
      (if (and (= *ArkZ_TogTab* "1") table_data)
        (progn
          (initget 1)
          (setq table_pt (getpoint "\nEspecifique o ponto para inserir a tabela: "))
          (if table_pt
            (CRIAR-TABELA-UTM table_pt table_data total_area 
                              h_tab_num *ArkZ_LayTab* 
                              *ArkZ_NomeLote* dec_tab_num)
          )
        )
      )
      
      ;; =============================================================
      ;; INSERIR MEMORIAL DESCRITIVO
      ;; =============================================================
      (if (and mem_data (> (length mem_data) 0))
        (progn
          (if (= *ArkZ_TogMemMText* "1")
            (progn
              (initget 1)
              (setq mem_pt (getpoint "\nEspecifique o ponto para inserir o MText do Memorial: "))
              (if mem_pt
                (progn
                  (setq mem_text (ArkZ:GerarTextoMemorial mem_data total_area 
                                  *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num))
                  (ArkZ:CriarMTextMemorial AcDoc mem_pt mem_text 
                    h_tab_num *ArkZ_LayTab* (* h_tab_num 80.0))
                  (princ "\n? Memorial Descritivo (MText) inserido com sucesso!")
                )
              )
            )
          )
          
          (if (= *ArkZ_TogMemTxt* "1")
            (progn
              (setq txt_path (getfiled "Salvar Memorial Descritivo" 
                               (strcat *ArkZ_NomeLote* ".txt") "txt" 1))
              (if txt_path
                (ArkZ:CriarArquivoTXT txt_path mem_data total_area 
                  *ArkZ_NomeLote* *ArkZ_Municip* dec_tab_num)
              )
            )
          )
        )
      )
      
      ;; =============================================================
      ;; LIMPEZA E FINALIZAÇÃO
      ;; =============================================================
      (setvar "clayer" oldlay)
      (princ "\n? Processamento concluído com V1 personalizado!")
    )
    (alert "Lista de pontos inválida!")
  )
  (princ)
)


;;;===========================================================================
;;; FUNÇÃO: ArkZ:NavegarVertices - Navegação com TAB/Setas (CORRIGIDA)
;;;===========================================================================
(defun ArkZ:NavegarVertices (/ total key)
  "Permite navegar visualmente entre os vértices da polilinha"
  (if *ArkZ_PLinePts*
    (progn
      (setq total (length *ArkZ_PLinePts*))
      (princ "\n[NAVEGAÇÃO VÉRTICE V1]")
      (princ "\n  TAB ou ?/? = Próximo vértice")
      (princ "\n  ? ou ? = Vértice anterior")
      (princ "\n  ENTER = Confirmar seleção\n")
      
      (ArkZ:DestacarVertice (nth *ArkZ_StartVtxIdx* *ArkZ_PLinePts*))
      
      (while (and (setq key (grread T 15 0)) 
                  (/= (car key) 3) 
                  (not (member (cadr key) '(13 32))))
        
        (cond
          ;; TAB (9) ou Seta Direita (45) ou Seta Cima (40) -> Avançar
          ((or (= (cadr key) 9) (= (cadr key) 45) (= (cadr key) 40))
           (setq *ArkZ_StartVtxIdx* (rem (1+ *ArkZ_StartVtxIdx*) total))
           (ArkZ:DestacarVertice (nth *ArkZ_StartVtxIdx* *ArkZ_PLinePts*))
           (princ (strcat "\rVértice V1: V" (itoa (1+ *ArkZ_StartVtxIdx*)) "  "))
          )
          ;; Seta Esquerda (37) ou Seta Baixo (38) -> Voltar
          ((or (= (cadr key) 37) (= (cadr key) 38))
           (setq *ArkZ_StartVtxIdx* (rem (+ *ArkZ_StartVtxIdx* (1- total)) total))
           (ArkZ:DestacarVertice (nth *ArkZ_StartVtxIdx* *ArkZ_PLinePts*))
           (princ (strcat "\rVértice V1: V" (itoa (1+ *ArkZ_StartVtxIdx*)) "  "))
          )
        )
      )
      (redraw)
      (princ (strcat "\n? Vértice V1 definido como: V" (itoa (1+ *ArkZ_StartVtxIdx*))))
    )
    (alert "Selecione uma Polilinha primeiro!")
  )
)

;;;===========================================================================
;;; FUNÇÃO: ArkZ:DestacarVertice - Desenha marca no vértice (CORRIGIDA)
;;;===========================================================================
(defun ArkZ:DestacarVertice (pt / size)
  "Desenha uma marca temporária destacada no vértice do AutoCAD"
  (redraw)
  (setq size (/ (getvar "VIEWSIZE") 30.0))
  (grdraw (list (- (car pt) size) (- (cadr pt) size)) 
          (list (+ (car pt) size) (+ (cadr pt) size)) 1 1)
  (grdraw (list (- (car pt) size) (+ (cadr pt) size)) 
          (list (+ (car pt) size) (- (cadr pt) size)) 1 1)
  (grdraw (list (- (car pt) (* size 0.5)) (- (cadr pt) (* size 0.5)))
          (list (+ (car pt) (* size 0.5)) (+ (cadr pt) (* size 0.5))) 2 1)
)

;;;===========================================================================
;;; COMANDOS DIRETOS
;;;===========================================================================
(defun c:ArkZVtx ( / AcDoc Space oldim h_vtx_num dec_vtx_num pt_start pt_leader text_leader ml_obj nb layObj)
  (vl-load-com)
  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object))
        Space (if (= 1 (getvar "CVPORT")) (vla-get-PaperSpace AcDoc) (vla-get-ModelSpace AcDoc)))
  
  (if (null *ArkZ_LayVtx*) (setq *ArkZ_LayVtx* "TGVERTICE"))
  (if (null *ArkZ_HVtx*)   (setq *ArkZ_HVtx* "2.5"))
  (if (null *ArkZ_DecVtx*) (setq *ArkZ_DecVtx* "2"))

  (if (null (tblsearch "LAYER" *ArkZ_LayVtx*))
    (progn
      (setq layObj (vla-add (vla-get-layers AcDoc) *ArkZ_LayVtx*))
      (vlax-put layObj 'Color 2)
    )
  )

  (setq h_vtx_num (distof *ArkZ_HVtx*)
        dec_vtx_num (atoi *ArkZ_DecVtx*))

  (setq oldim (getvar "dimzin"))
  (setvar "dimzin" 0)

  (initget 1)
  (setq pt_start (getpoint "\nEspecifique o ponto para inserir a anotação do vértice: "))
  (initget 1)
  (setq nb (getint "\nNúmero inicial do VÉRTICE <1>: "))
  (if (null nb) (setq nb 1))

  (setq pt_leader (polar pt_start (* pi 0.25) (* h_vtx_num 4.0))
        text_leader (strcat "VÉRTICE " (itoa nb) "\\P" "N: " (rtos (cadr pt_start) 2 dec_vtx_num) "\\P" "E: " (rtos (car pt_start) 2 dec_vtx_num)))
  
  (setvar "TEXTSIZE" h_vtx_num)
  (setq ml_obj (vla-AddMLeader Space (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble '(0 . 5)) (append pt_start pt_leader))) 0))
  (vla-put-Layer ml_obj *ArkZ_LayVtx*)
  (vla-put-TextString ml_obj text_leader)

  (setvar "dimzin" oldim)
  (princ "\n? Vértice inserido com sucesso!")
  (princ)
)

(defun c:ArkZAzi ( / AcDoc Space oldim a_base a_dir h_azi_num dec_azi_num p1 p2 pt_medio seg_len azimute nw_style nw_font layObj ang az)
  (vl-load-com)
  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object))
        Space (if (= 1 (getvar "CVPORT")) (vla-get-PaperSpace AcDoc) (vla-get-ModelSpace AcDoc)))

  (if (null *ArkZ_LayAzi*) (setq *ArkZ_LayAzi* "TGCOTA"))
  (if (null *ArkZ_HAzi*)   (setq *ArkZ_HAzi* "2.0"))
  (if (null *ArkZ_DecAzi*) (setq *ArkZ_DecAzi* "2"))

  (if (null (tblsearch "LAYER" *ArkZ_LayAzi*))
    (progn
      (setq layObj (vla-add (vla-get-layers AcDoc) *ArkZ_LayAzi*))
      (vlax-put layObj 'Color 7)
    )
  )

  (if (null (tblsearch "STYLE" "TGDdim"))
    (progn
      (setq nw_style (vla-add (vla-get-textstyles AcDoc) "TGDdim")
            nw_font (strcat (getenv "systemroot") "\\Fonts\\Arial.ttf"))
      (mapcar '(lambda (pr val) (vlax-put-property nw_style pr val))
           (list 'FontFile 'Height 'ObliqueAngle 'Width 'TextGenerationFlag)
           (list nw_font 0.0 0.0 1.0 0.0))
    )
  )

  (setq h_azi_num (distof *ArkZ_HAzi*)
        dec_azi_num (atoi *ArkZ_DecAzi*))

  (setq oldim (getvar "dimzin") a_base (getvar "ANGBASE") a_dir (getvar "ANGDIR"))
  (setvar "dimzin" 0) (setvar "ANGBASE" 0) (setvar "ANGDIR" 0)

  (initget 1)
  (setq p1 (getpoint "\nEspecifique o primeiro ponto (Origem): "))
  (initget 1)
  (setq p2 (getpoint p1 "\nEspecifique o segundo ponto (Destino): "))

  (setq seg_len (distance p1 p2)
        pt_medio (mapcar '* (mapcar '+ p1 p2) '(0.5 0.5 0.5))
        ang (angle p1 p2)
        az (- (/ pi 2.0) ang))
  (if (< az 0.0) (setq az (+ az (* 2.0 pi))))
  (setq azimute az)

  (defun TGTEXTO-AVULSO (ins_txt value_str a h_txt camada / nw_obj)
    (setq nw_obj (vla-addMtext Space (vlax-3d-point (trans ins_txt 1 0)) 0.0 value_str))
    (mapcar 
      '(lambda (pr val) (vlax-put nw_obj pr val))
      (list 'AttachmentPoint 'Height 'DrawingDirection 'InsertionPoint 'StyleName 'Layer 'Rotation)
      (list 5 h_txt 5 ins_txt "TGDdim" camada (if (and (< a (* pi 0.5)) (> a (* pi 1.5))) (setq a (+ a pi)) a))
    )
    (entmod
      (append
        (vl-remove-if '(lambda (x) (or (member (car x) '(90 63 421 45)) (< 419 (car x) 440))) (entget (entlast)))
        (list '(90 . 1) '(63 . 41) '(421 . 16770196) '(45 . 1.5))
      )
    )
    (entupd (entlast))
  )

  (TGTEXTO-AVULSO pt_medio (strcat "{\\fArial Narrow|b0|i0|c0|p34;Distancia " (rtos seg_len 2 dec_azi_num) "m\\P Azimute: " (format-azimuth (/ (* azimute 180.0) pi)) "}") (angle p1 p2) h_azi_num *ArkZ_LayAzi*)

  (setvar "dimzin" oldim) (setvar "ANGBASE" a_base) (setvar "ANGDIR" a_dir)
  (princ "\n? Azimute inserido com sucesso!")
  (princ)
)

;;;===========================================================================
;;; COMANDO: ArkZConfig - Configuração automática
;;;===========================================================================
(defun c:ArkZConfig ()
  (princ "\n=== CONFIGURAÇÃO DO ARKZLINE LABEL ===\n")
  
  ;; Criar estilos
  (if (null (tblsearch "STYLE" "TGDdim"))
    (progn
      (setq nw_style (vla-add (vla-get-textstyles (vla-get-activedocument (vlax-get-acad-object))) "TGDdim"))
      (setq nw_font (strcat (getenv "systemroot") "\\Fonts\\Arial.ttf"))
      (vla-put-FontFile nw_style nw_font)
      (vla-put-Height nw_style 0.0)
      (vla-put-ObliqueAngle nw_style 0.0)
      (vla-put-Width nw_style 1.0)
      (princ "\n? Estilo TGDdim criado")
    )
  )
  
  ;; Salvar zona padrão
  (if (null *ArkZ_Fuso*) (setq *ArkZ_Fuso* "22S"))
  (if (null *ArkZ_Meridiano*) (setq *ArkZ_Meridiano* "45°00' W"))
  (c:ArkZSaveZone)
  
  ;; Criar camadas
  (ArkZ:VerificarCamada (list "TGVERTICE" 2))
  (ArkZ:VerificarCamada (list "TGCOTA" 7))
  (ArkZ:VerificarCamada (list "TGTABELA" 4))
  (ArkZ:VerificarCamada (list "TGMEMORIAL" 5))
  
  (princ "\n? Configuração concluída!")
  (princ)
)


;;;===========================================================================
;;; FUNÇÃO DE AJUDA
;;;===========================================================================
;;;---------------------------------------------------------------------------
;;; StringWrap - Lee Mac, 2011 (modificado)
(defun StringWrap (str len / pos)
  (if (< len (strlen str))
    (cons
      (substr str 1
        (cond
          ((setq pos (vl-string-position 32 (substr str 1 len) nil t)))
          ((setq pos (1- len)) len)
        )
      )
      (StringWrap (substr str (+ 2 pos)) len)
    )
    (list str)
  )
)

;;;---------------------------------------------------------------------------
;;; Lê linhas de um arquivo de texto - Chat-GPT, 2024
(defun read-lines (filepath / file lines line)
  (setq lines nil)
  (if (and (setq filepath (findfile filepath))
           (setq file (open filepath "r")))
    (progn
      (while (setq line (read-line file))
        (setq lines (append lines (list line)))
      )
      (close file)
    )
    (progn
      (alert (strcat "Arquivo não encontrado: " filepath))
      nil
    )
  )
  lines
)

;;;---------------------------------------------------------------------------
;;; Processa texto para exibição em list_box
(defun process-text-for-display (lines max-width)
  (if lines
    (apply 'append 
      (mapcar '(lambda (line) (StringWrap line max-width)) lines)
    )
    (list "Nenhuma informação disponível.")
  )
)

;;;---------------------------------------------------------------------------
;;; Função ArkZMemorialDescritivo_Help (CORRIGIDA PARA BUSCAR NO DIRETÓRIO DO DCL)
(defun ArkZMemorialDescritivo_Help (/ dcl_id lines display-text txt_path dcl_path)
  
  ;; 1. Tenta encontrar o DCL para saber onde estamos
  (setq dcl_path (findfile "ArkZMemorialDescritivo.dcl"))
  
  ;; 2. Define o caminho do TXT baseado no caminho do DCL
  (if dcl_path
    (setq txt_path (strcat (vl-filename-directory dcl_path) "\\ArkZMemorialDescritivo.txt"))
    (setq txt_path "ArkZMemorialDescritivo.txt") ; Fallback para o Support Path
  )

  ;; 3. Verifica se o arquivo TXT existe no caminho definido
  (if (not (findfile txt_path))
    (progn
      (alert (strcat "O arquivo ArkZMemorialDescritivo.txt não foi encontrado.\n\n"
                     "Caminho procurado: " txt_path "\n\n"
                     "Certifique-se de que o arquivo .txt está na mesma pasta do .dcl."))
      (princ)
    )
    (progn
      ;; Arquivo existe, prossegue com a abertura do diálogo
      (if (and (setq dcl_id (load_dialog "ArkZMemorialDescritivo.dcl"))
               (new_dialog "ArkZMemorialDescritivo_Help" dcl_id))
        (progn
          ;; Carrega e exibe o texto do arquivo de ajuda usando o caminho completo
          (if (setq lines (read-lines txt_path))
            (progn
              (setq display-text (process-text-for-display lines 60))
              (start_list "lstAbout")
              (foreach line display-text
                (add_list line)
              )
              (end_list)
            )
            ;; Se não conseguir ler o arquivo
            (progn
              (start_list "lstAbout")
              (foreach line '("Erro ao ler o arquivo de ajuda." 
                             "Verifique se o arquivo não está corrompido."
                             ""
                             "Contate o suporte técnico.")
                (add_list line)
              )
              (end_list)
            )
          )
          
          ;; Exibe logo
          (MD_ShowSld "#img_logo" "ArkZMemorialDescritivo" "ArkZLogo" -2)
          
          ;; Preenche dados do registro
          (setq reg1 "ARK-Z ARQUITETURA")
          (setq reg2 "Aplicativos para o Autocad 2013 - 2026")
          (setq reg3 "License GNU GPLv3 © 2026 Ezequiel M Rezende")
          (setq reg4 "https://em-rezende.github.io/")
          (setq regdat (strcat reg1 "\n" reg2 "\n" reg3 "\n" reg4))
          (set_tile "reg_dat" regdat)
          
          ;; Define ação do botão OK
          (action_tile "btnOK" "(done_dialog 1)")
          
          ;; Inicia o diálogo
          (start_dialog)
          (unload_dialog dcl_id)
        )
        (alert "Erro ao carregar diálogo de ajuda.\nVerifique o arquivo ArkZMemorialDescritivo.dcl.")
      )
    )
  )
  (princ)
)

;;;===========================================================================
;;; COMANDO: ArkZTestCSV - Testar leitura do CSV
;;;===========================================================================
(defun c:ArkZTestCSV ( / loaded_data states cities first)
  (setq loaded_data (ArkZ:CarregarCidades))
  (setq states (car loaded_data))
  (setq cities (cadr loaded_data))
  
  (princ "\n=== TESTE DE CARREGAMENTO DO CSV ===")
  (princ (strcat "\nTotal de estados: " (itoa (length states))))
  (princ (strcat "\nTotal de cidades: " (itoa (length cities))))
  
  (if (> (length cities) 0)
    (progn
      (princ "\n\nPrimeiras 5 cidades carregadas:")
      (setq i 0)
      (foreach city cities
        (if (< i 5)
          (progn
            (princ (strcat "\n  " (nth 1 city) 
                          " | Lat: " (nth 2 city) 
                          " | Lon: " (nth 3 city)))
            (setq i (1+ i))
          )
        )
      )
    )
  )
  (princ)
)

(princ "\nComandos disponíveis:")
(princ "\n  ArkZMemorialDescritivo - Executar programa principal")
(princ "\n  ArkZConfig    - Configurar ambiente automaticamente")
(princ "\n  ArkZSaveZone  - Salvar zona no desenho")
(princ "\n  SelectCity    - Selecionar cidade e calcular fuso")
(princ "\n  ArkZVtx       - Inserir vértice avulso")
(princ "\n  ArkZAzi       - Inserir azimute avulso")
(princ "\n  ArkZTestCSV   - Testar carregamento do CSV")
(princ "\n  ArkZFecharCSV - Fecha polilinha a partir de pontos selecionados")
(princ)
