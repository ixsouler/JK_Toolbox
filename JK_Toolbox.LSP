;;; ================================================================
;;; 程序名称：JK工具箱 V1.0
;;; 功能描述：统一管理多个辅助工具，支持扩展
;;; 快捷键：JK（主界面）
;;; 作者：ixsouler
;;; 版本：1.0
;;; ================================================================

;;; ================================================================
;;; 第一部分：全局变量和配置
;;; ================================================================

;; 工具箱版本
(setq *JK-version* "V1.0")

;; 插件列表配置（可扩展）
;; 格式：(命令名 显示名称 功能描述 是否启用)
(setq *JK-plugin-list* 
  '(
    ("JK_FindDup" "批量查重" "查找重复文字并用不同颜色标记" T)
    ("JK_Replace" "批量替换" "支持3组文本同时替换" T)
    ("JK_TextEllipse" "文字套椭圆" "为文字中心添加固定大小椭圆" T)
    ;; 未来扩展插件示例（取消注释即可启用）
    ;; ("JK_Plugin3" "插件名称" "功能描述" T)
    ;; ("JK_Plugin4" "插件名称" "功能描述" T)
  )
)

;;; ================================================================
;;; 第二部分：主命令 - JK
;;; ================================================================

(defun c:JK (/ dcl_id dcl_file result selected-plugin)
  (vl-load-com)
  
  ;; 创建并显示主对话框
  (setq dcl_file (JK:create_main_dialog))
  (if (not dcl_file)
    (progn
      (princ "\n错误：无法创建对话框文件。")
      (exit)
    )
  )
  
  (setq dcl_id (load_dialog dcl_file))
  (if (not dcl_id)
    (progn
      (princ "\n错误：无法加载工具箱对话框。")
      (vl-file-delete dcl_file)
      (exit)
    )
  )
  
  (if (not (new_dialog "JK_Toolbox" dcl_id))
    (progn
      (unload_dialog dcl_id)
      (vl-file-delete dcl_file)
      (princ "\n错误：无法显示工具箱对话框。")
      (exit)
    )
  )
  
  ;; 设置对话框内容
  (JK:setup_dialog)
  
  ;; 按钮动作 - 使用统一命名
  (action_tile "btn_JK_FindDup" "(done_dialog 1)")
  (action_tile "btn_JK_Replace" "(done_dialog 2)")
  (action_tile "btn_JK_TextEllipse" "(done_dialog 3)")
  (action_tile "btn_about" "(done_dialog 99)")
  (action_tile "cancel" "(done_dialog 0)")
  
  ;; 显示对话框
  (setq result (start_dialog))
  (unload_dialog dcl_id)
  
  ;; 删除临时DCL文件
  (if (findfile dcl_file)
    (vl-file-delete dcl_file)
  )
  
  ;; 根据用户选择执行相应功能
  (cond
    ((= result 1) (JK:run_plugin "JK_FindDup"))
    ((= result 2) (JK:run_plugin "JK_Replace"))
    ((= result 3) (JK:run_plugin "JK_TextEllipse"))
    ((= result 99) (JK:show_about))
    (T (princ "\n已退出工具箱。"))
  )
  
  (princ)
)

;;; ================================================================
;;; 第三部分：对话框生成（修复版本）
;;; ================================================================

(defun JK:create_main_dialog (/ dcl_parts dcl_content dcl_file fp version-str)
  ;; 获取版本号字符串
  (setq version-str *JK-version*)
  
  ;; 将DCL内容拆分为多个短字符串
  (setq dcl_parts
    (list
      "JK_Toolbox : dialog {\n"
      "  label = \"JK工具箱 " version-str "\";\n"
      "  : column {\n"
      "    : row {\n"
      "      : text { label = \"═══════════════════════════════\"; alignment = centered; width = 40; }\n"
      "    }\n"
      "    : row {\n"
      "      : text { label = \"   欢迎使用 JK 工具箱\"; alignment = centered; width = 40; height = 2; }\n"
      "    }\n"
      "    : row {\n"
      "      : text { label = \"═══════════════════════════════\"; alignment = centered; width = 40; }\n"
      "    }\n"
      "    : spacer { height = 1; }\n"
      "    : boxed_column {\n"
      "      label = \"工具列表\";\n"
      "      : row {\n"
      "        : button { key = \"btn_JK_FindDup\"; label = \"批量查重\"; width = 18; height = 2; mnemonic = \"F\"; }\n"
      "        : button { key = \"btn_JK_Replace\"; label = \"批量替换\"; width = 18; height = 2; mnemonic = \"R\"; }\n"
      "      }\n"
      "      : row {\n"
      "        : button { key = \"btn_JK_TextEllipse\"; label = \"文字套椭圆\"; width = 18; height = 2; mnemonic = \"E\"; }\n"
      "        : button { key = \"btn_plugin4\"; label = \"工具4\"; width = 18; height = 2; is_enabled = false; }\n"
      "      }\n"
      "      : row {\n"
      "        : text { key = \"plugin_status\"; label = \"提示：灰色按钮为预留扩展位\"; alignment = centered; width = 40; }\n"
      "      }\n"
      "    }\n"
      "    : boxed_column {\n"
      "      label = \"状态信息\";\n"
      "      : text { key = \"status_text\"; label = \"请选择要运行的工具\"; alignment = centered; width = 40; height = 2; }\n"
      "    }\n"
      "    : spacer { height = 1; }\n"
      "    : row {\n"
      "      : button { key = \"btn_about\"; label = \"关于\"; width = 12; fixed_width = true; alignment = centered; }\n"
      "      : button { key = \"cancel\"; label = \"退出\"; width = 12; fixed_width = true; is_default = true; alignment = centered; }\n"
      "    }\n"
      "  }\n"
      "}\n"
    )
  )
  
  ;; 合并所有部分
  (setq dcl_content (apply 'strcat dcl_parts))
  
  ;; 写入临时文件
  (setq dcl_file (vl-filename-mktemp "JK_Toolbox.dcl"))
  (setq fp (open dcl_file "w"))
  (if fp
    (progn
      (write-line dcl_content fp)
      (close fp)
      dcl_file
    )
    (progn
      (princ "\n错误：无法创建临时对话框文件。")
      nil
    )
  )
)

;;; ================================================================
;;; 第四部分：对话框控制
;;; ================================================================

(defun JK:setup_dialog ()
  ;; 设置状态栏提示
  (action_tile "btn_JK_FindDup" 
    "(set_tile \"status_text\" \"批量查重：查找重复文字并用不同颜色标记\") (done_dialog 1)")
  (action_tile "btn_JK_Replace" 
    "(set_tile \"status_text\" \"批量替换：支持3组文本同时替换\") (done_dialog 2)")
  (action_tile "btn_JK_TextEllipse" 
    "(set_tile \"status_text\" \"文字套椭圆：为文字中心添加固定大小椭圆（长轴5，短轴2.5）\") (done_dialog 3)")
  (action_tile "btn_about" 
    "(set_tile \"status_text\" \"关于JK工具箱\") (done_dialog 99)")
  
  ;; 初始化状态信息
  (set_tile "status_text" "欢迎使用JK工具箱，请选择要运行的工具")
  
  ;; 设置键盘焦点到第一个按钮
  (mode_tile "btn_JK_FindDup" 2)
)

;;; ================================================================
;;; 第五部分：插件管理
;;; ================================================================

;; 运行指定插件
(defun JK:run_plugin (cmd)
  (princ (strcat "\n正在启动: " cmd " ..."))
  
  ;; 检查命令是否存在
  (if (not (eval (read (strcat "c:" cmd))))
    (progn
      (princ (strcat "\n警告：插件 '" cmd "' 未加载或不存在。"))
      (princ "\n请确保已加载对应的LISP文件。")
      (alert (strcat "插件未加载！\n\n请先加载 " cmd ".lsp 文件。"))
      (exit)
    )
  )
  
  ;; 调用命令
  (eval (read (strcat "(c:" cmd ")")))
  (princ (strcat "\n" cmd " 执行完成。"))
)

;; 显示关于信息
(defun JK:show_about ()
  (alert 
    (strcat 
      "JK工具箱 " *JK-version* "\n\n"
      "作者：ixsouler\n"
      "功能：统一管理多个辅助工具\n\n"
      "包含插件：\n"
      (JK:get_plugin_list_str)
      "\n"
      "使用说明：\n"
      "1. 输入 JK 打开工具箱\n"
      "2. 点击对应按钮运行工具\n"
      "3. 支持键盘快捷键操作\n\n"
      "扩展说明：\n"
      "- 修改 *JK-plugin-list* 可添加新插件\n"
      "- 插件命名规范：JK_XXX\n"
      "- 避免与其他命令冲突"
    )
  )
)

;; 获取插件列表字符串
(defun JK:get_plugin_list_str (/ result item)
  (setq result "")
  (foreach item *JK-plugin-list*
    (if (nth 3 item)
      (setq result (strcat result 
                          "  " (nth 1 item) "\n"
                          "    " (nth 2 item) "\n"))
    )
  )
  result
)

;;; ================================================================
;;; 第六部分：重命名的插件命令
;;; ================================================================

;; ================================================================
;; 插件1：批量查重 (原 FindDupText → JK_FindDup)
;; ================================================================

(defun c:JK_FindDup (/ ss ent-lst text-lst dup-groups color-list 
                        i j ent1 ent2 txt1 txt2 group-item 
                        color-index old-color all-texts processed
                        total-changed group-count)
  
  (princ "\n=== JK工具箱 - 批量查重工具 ===\n")
  
  ;; 提示用户选择单行文字对象
  (setq ss (ssget '((0 . "TEXT"))))
  
  ;; 如果没有选中对象，退出
  (if (null ss)
    (progn
      (princ "\n未选中任何单行文字对象！")
      (princ)
      (exit)
    )
  )
  
  ;; 初始化列表
  (setq ent-lst '())   ; 存储 (图元名 . 文字内容) 的列表
  (setq all-texts '()) ; 存储所有文字内容的列表，用于快速查找
  
  ;; 遍历选择集，收集文字信息
  (setq i 0)
  (repeat (sslength ss)
    (setq ent (ssname ss i))
    (setq txt (cdr (assoc 1 (entget ent))))  ; 获取文字内容
    (setq ent-lst (cons (cons ent txt) ent-lst))
    (setq all-texts (cons txt all-texts))
    (setq i (1+ i))
  )
  
  ;; 查找重复的文字内容及其对应的图元列表
  (setq dup-groups '())   ; 存储 (文字内容 . (图元1 图元2 ...)) 的列表
  (setq processed '())    ; 已处理的文字内容列表
  
  (foreach item ent-lst
    (setq txt (cdr item))
    
    ;; 如果该文字内容尚未处理
    (if (not (member txt processed))
      (progn
        ;; 统计该文字内容出现的次数
        (setq count 0)
        (setq same-ents '())
        (foreach itm ent-lst
          (if (= (cdr itm) txt)
            (progn
              (setq count (1+ count))
              (setq same-ents (cons (car itm) same-ents))
            )
          )
        )
        
        ;; 如果出现次数大于1，则记录到重复组
        (if (> count 1)
          (setq dup-groups (cons (cons txt same-ents) dup-groups))
        )
        
        ;; 标记为已处理
        (setq processed (cons txt processed))
      )
    )
  )
  
  ;; 如果没有重复内容，提示并退出
  (if (null dup-groups)
    (progn
      (princ "\n未发现重复内容的文字！")
      (princ)
      (exit)
    )
  )
  
  ;; 预定义颜色列表
  (setq color-list '(1 2 3 4 5 6 8 10 11 12 13 14 15 16 17 18 20 21))
  
  ;; 显示重复分组信息
  (princ "\n发现以下重复内容分组：")
  (setq group-index 0)
  (foreach group dup-groups
    (setq txt (car group))
    (setq ents (cdr group))
    (princ (strcat "\n  第 " (itoa (1+ group-index)) " 组: \"" txt "\" (共 " (itoa (length ents)) " 个)"))
    (setq group-index (1+ group-index))
  )
  
  ;; 询问用户是否继续
  (initget "Yes No")
  (setq user-response (getkword "\n是否继续变色操作？[Yes/No] <Yes>: "))
  (if (and user-response (= user-response "No"))
    (progn
      (princ "\n操作已取消。")
      (princ)
      (exit)
    )
  )
  
  ;; 为每组重复内容分配不同颜色并变色
  (princ "\n正在为重复文字分配颜色...")
  (setq group-index 0)
  (setq total-changed 0)
  (setq group-count (length dup-groups))
  
  (foreach group dup-groups
    (setq txt (car group))
    (setq ents (cdr group))
    
    ;; 从颜色列表中取色
    (setq color-index (nth (rem group-index (length color-list)) color-list))
    
    ;; 获取该组中第一个文字对象的原始颜色
    (setq first-ent (car ents))
    (setq ent-data (entget first-ent))
    (setq old-color (cdr (assoc 62 ent-data)))
    
    ;; 如果原颜色为随层或默认色，或与分配颜色相同，进行调整
    (if (or (null old-color) (= old-color 7))
      (setq old-color nil)
    )
    
    ;; 如果分配的颜色与原始颜色相同，使用备用颜色
    (if (and old-color (= old-color color-index))
      (progn
        (setq alt-color nil)
        (setq try-index (1- (length color-list)))
        (while (and (>= try-index 0) (null alt-color))
          (setq candidate (nth try-index color-list))
          (if (/= candidate old-color)
            (setq alt-color candidate)
          )
          (setq try-index (1- try-index))
        )
        (if alt-color
          (setq color-index alt-color)
          (setq color-index 1)
        )
      )
    )
    
    ;; 遍历该组所有图元，改变颜色
    (foreach ent ents
      (setq ent-data (entget ent))
      (if (assoc 62 ent-data)
        (setq ent-data (subst (cons 62 color-index) (assoc 62 ent-data) ent-data))
        (setq ent-data (append ent-data (list (cons 62 color-index))))
      )
      (entmod ent-data)
      (entupd ent)
      (setq total-changed (1+ total-changed))
    )
    
    (setq group-index (1+ group-index))
  )
  
  ;; 输出结果统计
  (princ (strcat "\n完成！共处理 " (itoa total-changed) " 个重复文字对象，"
                 "分为 " (itoa group-count) " 组不同颜色。"))
  (princ "\n提示：使用 'CHPROP' 命令可批量恢复颜色。")
  (princ)
)

;; ================================================================
;; 插件2：批量替换 (原 YY → JK_Replace)
;; ================================================================

;; 全局变量 - 保存上次使用的替换对
(setq *JK-REPLACE-last-pairs* nil)

(defun c:JK_Replace (/ old_new_pairs)
  (vl-load-com)
  
  (princ "\n=== JK工具箱 - 批量替换工具 ===\n")
  
  ;; 显示对话框获取替换对
  (setq old_new_pairs (JK_Replace:get_pairs))
  
  ;; 如果用户取消了对话框，则退出
  (if (not old_new_pairs)
    (princ "\n用户取消操作。")
    (progn
      ;; 执行替换操作
      (JK_Replace:execute old_new_pairs)
      ;; 保存本次替换对供下次使用
      (setq *JK-REPLACE-last-pairs* old_new_pairs)
      (princ "\n替换操作完成！")
    )
  )
  (princ)
)

;; 获取替换对（对话框）
(defun JK_Replace:get_pairs (/ dcl_id dcl_file result pair1 pair2 pair3 
                               old1 old2 old3 new1 new2 new3)
  (setq dcl_file (JK_Replace:create_dialog))
  
  (if (not dcl_file)
    (progn
      (princ "\n错误：无法创建替换对话框文件。")
      nil
    )
    (progn
      (setq dcl_id (load_dialog dcl_file))
      
      (if (not dcl_id)
        (progn
          (princ "\n错误：无法加载对话框文件。")
          (vl-file-delete dcl_file)
          nil
        )
        (progn
          (if (not (new_dialog "JK_Replace_Dialog" dcl_id))
            (progn
              (unload_dialog dcl_id)
              (vl-file-delete dcl_file)
              (princ "\n错误：无法显示对话框。")
              nil
            )
            (progn
              ;; 设置默认值
              (if *JK-REPLACE-last-pairs*
                (progn
                  (setq pair1 (nth 0 *JK-REPLACE-last-pairs*))
                  (setq pair2 (nth 1 *JK-REPLACE-last-pairs*))
                  (setq pair3 (nth 2 *JK-REPLACE-last-pairs*))
                  (set_tile "old1" (car pair1))
                  (set_tile "new1" (cadr pair1))
                  (set_tile "old2" (car pair2))
                  (set_tile "new2" (cadr pair2))
                  (set_tile "old3" (car pair3))
                  (set_tile "new3" (cadr pair3))
                )
                (progn
                  (set_tile "old1" "施工图")
                  (set_tile "new1" "竣工图")
                  (set_tile "old2" "F2318S")
                  (set_tile "new2" "F2318Z")
                  (set_tile "old3" "2025.02")
                  (set_tile "new3" "2025.08")
                )
              )
              
              (mode_tile "old1" 2)
              
              (action_tile "accept" 
                "(setq old1 (get_tile \"old1\"))
                 (setq new1 (get_tile \"new1\"))
                 (setq old2 (get_tile \"old2\"))
                 (setq new2 (get_tile \"new2\"))
                 (setq old3 (get_tile \"old3\"))
                 (setq new3 (get_tile \"new3\"))
                 (setq pair1 (list old1 new1))
                 (setq pair2 (list old2 new2))
                 (setq pair3 (list old3 new3))
                 (done_dialog 1)")
              
              (action_tile "cancel" "(done_dialog 0)")
              
              (setq result (start_dialog))
              (unload_dialog dcl_id)
              (vl-file-delete dcl_file)
              
              (if (= result 1)
                (list pair1 pair2 pair3)
                nil
              )
            )
          )
        )
      )
    )
  )
)

;; 创建替换对话框（拆分长字符串）
(defun JK_Replace:create_dialog (/ dcl_parts dcl_content dcl_file fp)
  (setq dcl_parts
    (list
      "JK_Replace_Dialog : dialog {\n"
      "  label = \"JK工具箱 - 批量替换\";\n"
      "  : column {\n"
      "    : boxed_column {\n"
      "      label = \"第一组替换\";\n"
      "      : edit_box { key = \"old1\"; label = \"替换前:\"; edit_width = 25; width = 30; }\n"
      "      : edit_box { key = \"new1\"; label = \"替换后:\"; edit_width = 25; width = 30; }\n"
      "    }\n"
      "    : boxed_column {\n"
      "      label = \"第二组替换\";\n"
      "      : edit_box { key = \"old2\"; label = \"替换前:\"; edit_width = 25; width = 30; }\n"
      "      : edit_box { key = \"new2\"; label = \"替换后:\"; edit_width = 25; width = 30; }\n"
      "    }\n"
      "    : boxed_column {\n"
      "      label = \"第三组替换\";\n"
      "      : edit_box { key = \"old3\"; label = \"替换前:\"; edit_width = 25; width = 30; }\n"
      "      : edit_box { key = \"new3\"; label = \"替换后:\"; edit_width = 25; width = 30; }\n"
      "    }\n"
      "  }\n"
      "  spacer;\n"
      "  : row {\n"
      "    : button { key = \"accept\"; label = \"确定\"; is_default = true; fixed_width = true; width = 12; alignment = centered; }\n"
      "    : button { key = \"cancel\"; label = \"取消\"; is_default = false; fixed_width = true; width = 12; alignment = centered; }\n"
      "  }\n"
      "}\n"
    )
  )
  
  (setq dcl_content (apply 'strcat dcl_parts))
  
  (setq dcl_file (vl-filename-mktemp "JK_Replace.dcl"))
  (setq fp (open dcl_file "w"))
  (if fp
    (progn
      (write-line dcl_content fp)
      (close fp)
      dcl_file
    )
    (progn
      (princ "\n错误：无法创建临时对话框文件。")
      nil
    )
  )
)

;; 执行替换
(defun JK_Replace:execute (old_new_pairs / ss i ent obj txt found_count pair 
                                           old_txt new_txt selection-flag
                                           replaced-count total-processed)
  (princ "\n开始替换文本...")
  
  ;; 询问用户选择范围
  (initget "All Select")
  (setq selection-flag 
    (getkword "\n选择替换范围 [全部(All)/手动选择(Select)] <All>: "))
  
  (if (or (null selection-flag) (= selection-flag "All"))
    (progn
      (setq ss (ssget "_X" '((0 . "MTEXT,TEXT"))))
      (princ "\n正在处理所有文本对象...")
    )
    (progn
      (princ "\n请选择要替换的文本对象...")
      (setq ss (ssget '((0 . "MTEXT,TEXT"))))
    )
  )
  
  (if (null ss)
    (progn
      (princ "\n未找到任何文本对象。")
      (exit)
    )
  )
  
  (setq total-processed 0)
  (setq found_count 0)
  
  (repeat (setq i (sslength ss))
    (setq ent (ssname ss (setq i (1- i))))
    (setq obj (vlax-ename->vla-object ent))
    (setq txt (vla-get-textstring obj))
    (setq replaced-count 0)
    
    (foreach pair old_new_pairs
      (setq old_txt (car pair))
      (setq new_txt (cadr pair))
      
      (if (and old_txt new_txt (/= old_txt "") (/= new_txt old_txt))
        (progn
          (if (vl-string-search (strcase old_txt) (strcase txt))
            (progn
              (setq txt (vl-string-subst new_txt old_txt txt))
              (setq replaced-count (1+ replaced-count))
            )
          )
        )
      )
    )
    
    (if (> replaced-count 0)
      (progn
        (vla-put-textstring obj txt)
        (setq found_count (1+ found_count))
        (setq total-processed (+ total-processed replaced-count))
      )
    )
  )
  
  (princ (strcat "\n" (itoa total-processed) " 处文本被替换，"))
  (princ (strcat "涉及 " (itoa found_count) " 个文本对象。"))
  
  (if (= total-processed 0)
    (princ "\n未找到匹配的文本内容。请检查替换条件。")
  )
)

;; ================================================================
;; 插件3：文字套椭圆 (原 EE → JK_TextEllipse)
;; ================================================================

(defun c:JK_TextEllipse (/ ss i ent obj minPt maxPt cenX cenY ang center longRad shortRad)
  (vl-load-com)
  
  (princ "\n=== JK工具箱 - 文字套椭圆工具 ===\n")
  
  (setvar "cmdecho" 0)
  
  ;; 固定参数：长轴半径5，短轴半径2.5
  (setq longRad 5.0)
  (setq shortRad 2.5)
  
  ;; 获取选择集（优先使用预先选中的对象）
  (setq ss (ssget "_I"))
  (if (null ss)
    (progn
      (princ "\n请选择文字对象: ")
      (setq ss (ssget '((0 . "TEXT,MTEXT"))))
    )
    (progn
      ;; 检查预选对象是否都是文字
      (setq i 0)
      (setq hasBad nil)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq obj (vlax-ename->vla-object ent))
        (if (not (member (vla-get-ObjectName obj) '("AcDbText" "AcDbMText")))
          (setq hasBad T)
        )
        (setq i (1+ i))
      )
      (if hasBad
        (progn
          (princ "\n预选对象包含非文字，请重新选择: ")
          (setq ss (ssget '((0 . "TEXT,MTEXT"))))
        )
      )
    )
  )
  
  (if (null ss)
    (progn
      (princ "\n未选择文字，退出。")
      (setvar "cmdecho" 1)
      (princ)
      (exit)
    )
  )
  
  (setq i 0)
  (repeat (sslength ss)
    (setq ent (ssname ss i))
    (setq obj (vlax-ename->vla-object ent))
    
    ;; 获取文字边界框
    (vla-GetBoundingBox obj 'minPt 'maxPt)
    (setq minPt (vlax-safearray->list minPt))
    (setq maxPt (vlax-safearray->list maxPt))
    
    ;; 计算中心点
    (setq cenX (/ (+ (car minPt) (car maxPt)) 2.0))
    (setq cenY (/ (+ (cadr minPt) (cadr maxPt)) 2.0))
    (setq center (list cenX cenY 0.0))
    
    ;; 获取文字旋转角
    (if (= (vla-get-ObjectName obj) "AcDbText")
      (setq ang (vla-get-Rotation obj))
      (setq ang 0.0)
    )
    
    ;; 创建椭圆（随当前图层）
    (setq ellipseObj
      (vla-addEllipse
        (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))
        (vlax-3d-point center)
        (vlax-3d-point (list (* longRad (cos ang)) (* longRad (sin ang)) 0.0))
        (/ shortRad longRad)
      )
    )
    
    ;; 特性随当前图层
    (vla-put-Color ellipseObj acByLayer)
    (vla-put-Linetype ellipseObj "ByLayer")
    (vla-put-Lineweight ellipseObj acLnWtByLayer)
    
    (setq i (1+ i))
  )
  
  (princ (strcat "\n完成！为 " (itoa (sslength ss)) " 个文字添加椭圆。"))
  (princ "\n椭圆规格：长轴半径5，短轴半径2.5")
  (setvar "cmdecho" 1)
  (princ)
)

;;; ================================================================
;;; 第七部分：工具函数
;;; ================================================================

;; 查看已加载的插件
(defun c:JKPLUGINS (/ item)
  (princ "\n=== JK工具箱 - 插件状态 ===\n")
  (princ "当前版本: " *JK-version* "\n\n")
  (foreach item *JK-plugin-list*
    (princ (strcat (nth 1 item) " [" (nth 0 item) "]"))
    (princ (strcat " - " (nth 2 item) "\n"))
    (if (eval (read (strcat "c:" (nth 0 item))))
      (princ "  状态: [已加载]\n")
      (princ "  状态: [未加载]\n")
    )
  )
  (princ)
)

;; 显示帮助信息
(defun c:JKHELP ()
  (princ "\n=== JK工具箱 - 帮助 ===\n")
  (princ "\n命令列表：")
  (princ "\n  JK            - 打开工具箱主界面")
  (princ "\n  JKPLUGINS     - 查看所有插件状态")
  (princ "\n  JKHELP        - 显示此帮助信息")
  (princ "\n\n包含工具：")
  (foreach item *JK-plugin-list*
    (if (nth 3 item)
      (princ (strcat "\n  " (nth 0 item) " - " (nth 1 item)))
    )
  )
  (princ "\n\n使用说明：")
  (princ "\n1. 输入 JK 打开工具箱")
  (princ "\n2. 点击按钮运行对应工具")
  (princ "\n3. 所有插件均以 JK_ 开头，避免命令冲突")
  (princ)
)

;;; ================================================================
;;; 第八部分：初始化
;;; ================================================================

(defun JK:init ()
  (princ "\n╔════════════════════════════════════════╗")
  (princ "\n║  JK工具箱 " *JK-version* " 已成功加载！  ║")
  (princ "\n╠════════════════════════════════════════╣")
  (princ "\n║  输入 JK 打开工具箱主界面               ║")
  (princ "\n║  输入 JKPLUGINS 查看插件状态            ║")
  (princ "\n║  输入 JKHELP 查看帮助信息               ║")
  (princ "\n╚════════════════════════════════════════╝")
  (princ)
)

;; 加载时初始化
(JK:init)

(princ)