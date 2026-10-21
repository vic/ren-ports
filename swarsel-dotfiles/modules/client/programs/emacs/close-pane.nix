{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.emacs-init.homeManager.config.programs.emacs.init.prelude = ''
    (defun swarsel/kill-buffer-delete-window ()
      (let ((win (get-buffer-window (current-buffer))))
        (when (and win (not (one-window-p)))
          (delete-window win))))

    (add-hook 'kill-buffer-hook #'swarsel/kill-buffer-delete-window)
  '';
}
