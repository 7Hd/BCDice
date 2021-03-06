# frozen_string_literal: true

module BCDice
  module GameSystem
    class RoleMaster < Base
      # ゲームシステムの識別子
      ID = 'RoleMaster'

      # ゲームシステム名
      NAME = 'ロールマスター'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ろおるますたあ'

      # ダイスボットの使い方
      HELP_MESSAGE = "上方無限ロール(xUn)の境界値を96にセットします。\n"

      def initialize
        super
        @upper_dice_reroll_threshold = 96
      end
    end
  end
end
