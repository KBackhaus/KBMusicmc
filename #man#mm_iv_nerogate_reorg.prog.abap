*&---------------------------------------------------------------------*
*& Report /MAN/MM_IV_NEROGATE_REORG
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*********************************************************** MANTOP 2023
*
* INHALT : Kurze Reportbeschreibung
*---------------------------------------------------------------------
* (C) 2023 MAN
*---------------------------------------------------------------------
*
* HISTORIE : ADDO_DV_Konzept
* --------------------------
*
* Vers.| Ersteller    | Datum    | Tätigkeiten / Änderungen
*      | Firma        |          |
*      | Auftrag      | Release  |
* -----+--------------+----------+------------------------------------
*  01  | b0964        | 008.2023 | Ersteinsatz
*      |              |          |
*      |              |          |
* -----+--------------+----------+------------------------------------
*  02  |              |          |
*      |              |          |
*      |              |          |
* -----+--------------+----------+------------------------------------
**********************************************************************

*Vorrausetzung:
*
*Auf dem Rechner des Anwenders oder im NERO-Gate müssen die beiden .BAT Dateien
*
*FileShow und FileDelete in einem Verzeichniss liegen.
*
*Stand 24.08.2023 habe ich die in den Ordner : Z:\001batch kopiert wobei Laufwerk Z: mit dem
*NERO-Gate : \\mndemucfs025 verknüpft ist.
*
*HINWEIS : Das FileDelete Skript löscht "unwiederuflich" direkt via cmd.exe Kommando!

*Prerequisite:
*
*The two .BAT files must be on the user's computer or in the NERO Gate
*
*FileShow and FileDelete are in one directory.
*
*As of August 24th, 2023, I copied the into the folder: Z:\001batch, where drive Z: with the
*NERO-Gate : \\mndemucfs025 is linked.
*
*NOTE : The FileDelete script deletes "irreversibly" directly via cmd.exe command!

REPORT /man/mm_iv_nerogate_reorg.

DATA : gc_text_question TYPE string,
       gv_batfile       TYPE string,
       gv_answer(1)     TYPE c.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
PARAMETERS : pa_bat     TYPE string DEFAULT 'Z:\001batch\FileShow.bat' OBLIGATORY LOWER CASE,
             pa_path    TYPE string DEFAULT 'C:\temp' OBLIGATORY LOWER CASE,
             pa_tage(3) TYPE n DEFAULT '1' OBLIGATORY,
             pa_logf    type string DEFAULT 'C:\temp\logfile_nero_reorg.txt' LOWER CASE.
SELECTION-SCREEN END OF BLOCK b01.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_bat.
  PERFORM f4_filename.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_path.
  PERFORM f4_path.

START-OF-SELECTION.

  gv_batfile = pa_bat.
  TRANSLATE gv_batfile TO UPPER CASE.

  FIND 'DELETE' IN gv_batfile.
  IF sy-subrc = 0.
    gc_text_question = |DIRECTORY: | && pa_path && | DELETE ALL FILES OLDER | && pa_tage && | DAYS!|.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question  = gc_text_question
        text_button_1  = 'YES'(001)
        text_button_2  = 'NO'(002)
        default_button = '2'
      IMPORTING
        answer         = gv_answer
      EXCEPTIONS
        text_not_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0 OR gv_answer <> '1'.
      MESSAGE s208(00) WITH 'Execution stopped by user!'.
      EXIT.
    ENDIF.
  ENDIF.

  PERFORM cmd_exe.

FORM cmd_exe.

  DATA : i_params TYPE string.
  DATA : i_path TYPE string.
  DATA : i_tage TYPE string.
  DATA : i_bat  TYPE string.
  DATA : i_logf type string.

  i_bat    = pa_bat.
  i_path   = pa_path.
  i_tage   = pa_tage.
  i_logf   = pa_logf.

  "i_params = '/k "' && i_bat && | "| && i_path && |" | && i_tage && |"|.
  i_params = '/k "' && i_bat && | "| && i_path && |" | && i_tage && | "| && i_logf && |"| && |"|.

  cl_gui_frontend_services=>execute(
    EXPORTING
      application = 'cmd.exe'
      "parameter   = '/k "C:\Users\b0964\batchfiles\fileshow "C:\temp" 1"'
      parameter   = i_params
      maximized   = 'X'
      "minimized   = 'X' " disable cmd flash
      "synchronous = 'X' " wait for cmd to finish
    EXCEPTIONS
      OTHERS      = 10 ).

ENDFORM.

FORM f4_filename.
  FIELD-SYMBOLS : <fs1> TYPE any.
  DATA : ls_window_title TYPE string.
  DATA : lt_file_table TYPE filetable,
         lv_rc         TYPE i.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = ls_window_title
      default_filename        = '*.*'
      multiselection          = ''
    CHANGING
      file_table              = lt_file_table
      rc                      = lv_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      OTHERS                  = 4.

  LOOP AT  lt_file_table ASSIGNING <fs1>.
    MOVE <fs1> TO pa_bat.
  ENDLOOP.
ENDFORM.

FORM f4_path.
  DATA : lv_title TYPE string.

  lv_title = 'Select Directory'.

  cl_gui_frontend_services=>directory_browse(
  EXPORTING
   window_title    = lv_title
  CHANGING
   selected_folder = pa_path
  EXCEPTIONS
   cntl_error      = 1
   error_no_gui    = 2
   OTHERS          = 3 ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    EXIT.
  ENDIF.

ENDFORM.
