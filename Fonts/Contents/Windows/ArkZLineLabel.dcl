//
//  ArkZLineLabel.dcl
//  Version: 2.3 - Com Botões de Modo de Operação e Aplicar
//

ArkZLineLabel: dialog {
    label = "ArkZLineLabel - Configurações";
    fixed_height = true;
    alignment = centered;
    initial_focus = "accept";

: row {
    alignment = centered;
    fixed_width = true;
    fixed_height = true;  
    : image {
        key = "#img_logo";
        alignment = centered;
        fixed_width = true;
        fixed_height = true;    
        is_tab_stop = false;
        width = 14;
        aspect_ratio = 0.45;
        color = dialog_background;
    }
	
    : column {
        : paragraph {
            key = "#arkz";
            : text_part { label = " "; alignment = centered; }
            : text_part { label = "ARK-Z ARQUITETURA LTDA"; alignment = centered; }
            : text_part { label = "Padronização de menu para o AutoCAD"; alignment = centered; }
        }
    }    
}

: image {key = "sep1"; color = dialog_background; width = 1; height = 0.5;}

: row {
: column {
    fixed_width = true;
    fixed_height = true;
    
    : boxed_column {
        label = "Modo de Operação";
        fixed_height = true;
        : button { 
            key = "mode_sel"; 
            label = "Selecionar poligonal existente..."; 
            width = 20;
        }
        : button { 
            key = "mode_csv"; 
            label = "Importar pontos de arquivo CSV..."; 
            width = 20;
        }
    }

    : boxed_column {
        label = "Opções do CSV (Apenas para Importação)";
        key = "grp_csv";
        : toggle { key = "tog_poly"; label = "Criar Polilinha a partir dos pontos do CSV"; }
    }

    : boxed_column {
        label = "Elementos a Inserir";
        : toggle { key = "tog_vtx"; label = "Inserir anotações nos Vértices (Multileaders)"; }
        : toggle { key = "tog_azi"; label = "Inserir anotações (Azimute/Distância)"; }
        : toggle { key = "tog_tab"; label = "Gerar Tabela de Coordenadas UTM"; }
        : toggle { key = "tg_mem_mtext"; label = "Criar memorial descritivo (MText)"; }
        : toggle { key = "tg_mem_txt"; label = "Exportar Memorial Descritivo (.TXT)"; }
    }
    
    : boxed_row {
        label = "Inserir Avulso";
        : button { key = "btn_vtx_avulso"; label = "Vértice"; width = 15; }
        : button { key = "btn_azi_avulso"; label = "Azimute"; width = 15; }
    }
	
    : boxed_column {
        label = "Navegação de Vértices";
        : row {
            : text { label = "V1:"; width = 5; }
            : text { key = "txt_v1_display"; label = "1"; width = 5; }
            : text { label = "de"; width = 5; }
            : text { key = "txt_total_vtx"; label = "0"; width = 5; }
        }
        : row {
            : button { key = "btn_prev_vtx"; label = "<"; width = 8; }
            : button { key = "btn_next_vtx"; label = ">"; width = 8; }
            : button { key = "btn_invert_dir"; label = "Inverter"; width = 12; }
        }
        : row {
            : text { 
                key = "txt_sentido_status"; 
                label = "Sentido: Horário"; 
                width = 25;
                alignment = centered;
            }
        }
    }

}// column

: column {
    fixed_width = true;
    fixed_height = true;
    
    : boxed_row {
        label = "Camadas (Layers)";
        : column {
            : text { label = "   Camada Vértices:"; }
            : text { label = "   Camada Azimutes:"; }
            : text { label = "   Camada Tabela:"; }
        }
        : column {
            : edit_box { key = "lay_vtx"; edit_width = 15; }
            : edit_box { key = "lay_azi"; edit_width = 15; }
            : edit_box { key = "lay_tab"; edit_width = 15; }
        }
    }
    
    : boxed_row {
        label = "Alturas de Texto";
        : column {
            : text { label = "Vértices"; }
            : text { label = "Azimutes"; }
            : text { label = "Tabela"; }
        }
        : column {
            : edit_box { key = "h_vtx"; edit_width = 15; }
            : edit_box { key = "h_azi"; edit_width = 15; }
            : edit_box { key = "h_tab"; edit_width = 15; }
        }
    }
    
    : boxed_row {
        label = "Casas Decimais (Precisão)";
        : column {
            : text { label = "    Nos Vértices:"; }
            : text { label = "    Nos Azimutes:"; }
            : text { label = "    Na Tabela:"; }
        }
        : column {
            : edit_box { key = "dec_vtx"; edit_width = 15; }
            : edit_box { key = "dec_azi"; edit_width = 15; }
            : edit_box { key = "dec_tab"; edit_width = 15; }
        }
    }
    
    : boxed_row {
        label = "Sistema UTM";
        : column {
            : row {
                : text { label = "Fuso:"; width = 8; }
                : text { key = "txt_fuso_display"; label = "23S"; width = 10; }
            }
            : row {
                : text { label = "Meridiano:"; width = 12; }
                : text { key = "txt_meridiano_display"; label = "45°00' W"; width = 15; }
            }
            : row {
                : button {
                    key = "btn_detect_c3d";
                    label = "Detectar do Civil 3D";
                    width = 18;
                }
                : button {
                    key = "btn_select_city";
                    label = "Selecionar Cidade...";
                    width = 18;
                }
            }
        }
    }
}// column
} // row

: boxed_row {
    label = "Dados do Imóvel";
    : edit_box { label = "Descrição:"; key = "eb_nome_lote"; edit_width = 30; }
    : edit_box { label = "Município:"; key = "eb_municipio"; edit_width = 18; }
}

//
: image {key = "sep2"; color = dialog_background; width = 1; height = 0.5;}
//

: row {
    width = 25;
    fixed_width = true;
    alignment = centered;
    : button { 
        label = "Aplicar"; 
        key = "btn_apply"; 
        width = 12; 
        fixed_width = true;
        is_default = true;
    }

    : button { 
        label = "Sair"; 
        key = "cancel"; 
        width = 12; 
        fixed_width = true; 
        is_cancel = true; 
    }
    : button { 
        label = "Ajuda"; 
        key = "help"; 
        width = 12; 
        fixed_width = true; 
    }	
}
}

// ----------------------------------------------------------------
// Tela de Configuração do CSV
// ----------------------------------------------------------------
ArkZLineCSV : dialog {
    label = "Configurações de Importação CSV";
    fixed_width = true;
    : row {
        : edit_box { key = "csv_path"; label = "Arquivo:"; edit_width = 45; fixed_width = true; read_only = true; }
        : button { key = "btn_browse"; label = "Procurar..."; width = 12; fixed_width = true; }
    }
    : boxed_row {
        label = "Parâmetros do Arquivo";
        : popup_list { key = "csv_sep"; label = "Separador:"; width = 20; }
        : toggle { key = "csv_skip"; label = "Ignorar a 1ª linha (Cabeçalho)"; }
    }
    : boxed_row {
        label = "Mapeamento de Coordenadas (Colunas)";
        alignment = left;
        : popup_list { key = "col_x"; label = "Coluna X (Este):"; width = 20; }
        : popup_list { key = "col_y"; label = "Coluna Y (Norte):"; width = 20; }
    }
    : boxed_column {
        label = "Pré-visualização dos dados brutos (Primeiras 5 linhas)";
        : list_box { key = "csv_preview"; width = 50; height = 8; fixed_width_font = true; }
    }
    : row {
        alignment = centered;
        fixed_width = true;
        : button { key = "csv_accept"; label = "Importar"; width = 15; is_default = true; }
        : button { key = "csv_cancel"; label = "Voltar"; width = 15; is_cancel = true; }
    }
}

// ----------------------------------------------------------------
// Diálogo de Seleção de Cidade
// ----------------------------------------------------------------
SelectCity : dialog {
    label = "Seleção de Cidade para Fuso UTM";
    fixed_height = true;
    
    : column {
        : row {
            : popup_list {
                key = "state_list";
                label = "Estado:";
                width = 25;
                fixed_width = true;
                edit_width = 20;
            }
            : popup_list {
                key = "city_list";
                label = "Cidade:";
                width = 30;
                fixed_width = true;
                edit_width = 25;
            }
        }
        
        : boxed_row {
            label = "Dados da Cidade Selecionada";
            : column {
                : edit_box {
                    key = "id";
                    label = "Código:";
                    width = 30;
                    fixed_width = true;
                    edit_width = 25;
                    edit_limit = 20;
                    read_only = true;
                }
                : edit_box {
                    key = "city";
                    label = "Cidade:";
                    width = 30;
                    fixed_width = true;
                    edit_width = 25;
                    edit_limit = 50;
                    read_only = true;
                }
                : edit_box {
                    key = "latitude";
                    label = "Latitude:";
                    width = 30;
                    fixed_width = true;
                    edit_width = 25;
                    edit_limit = 20;
                    read_only = true;
                }
                : edit_box {
                    key = "longitude";
                    label = "Longitude:";
                    width = 30;
                    fixed_width = true;
                    edit_width = 25;
                    edit_limit = 20;
                    read_only = true;
                }
            }
        }
        
        : boxed_row {
            label = "Fuso UTM Calculado";
            : column {
                : text {
                    key = "txt_fuso";
                    label = "Fuso: Aguardando seleção...";
                    width = 30;
                }
                : text {
                    key = "txt_meridiano";
                    label = "Meridiano: Aguardando seleção...";
                    width = 35;
                }
            }
        }
        
        : row {
            fixed_width = true;
            alignment = centered;
            : button {
                key = "ok";
                label = "Confirmar";
                is_default = true;
                width = 15;
                fixed_width = true;
            }
            : button {
                key = "cancel";
                label = "Cancelar";
                is_cancel = true;
                width = 15;
                fixed_width = true;
            }
        }
    }
}

// ----------------------------------------------------------------
// Help Dialog
// ----------------------------------------------------------------
ArkZLineLabel_Help : dialog {
    label = "Informações sobre Ark-Z Arquitetura";
    : image {
        key = "#img_logo";
        alignment = centered;
        is_tab_stop = false;
        width = 14;
        aspect_ratio = 0.45;
        fixed_width = true;
        color = dialog_background;
    }
    : list_box {
        width = 65;
        height = 16;
        key = "lstAbout";
        fixed_width = false;
        fixed_width_font = true;
    }
    : text { label = "Informações de registro do programa:"; }
    : text { key = "reg_dat"; fixed_width_font = true; height = 4.5; }
    : button {
        fixed_width = true;
        is_cancel = true;
        is_default = true;
        key = "btnOK";
        label = "OK";
        alignment = centered;
        width = 12;
    }
}