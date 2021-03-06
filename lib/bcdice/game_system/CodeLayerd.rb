# frozen_string_literal: true

require 'bcdice/modifier_formatter'

module BCDice
  module GameSystem
    class CodeLayerd < Base
      include ModifierFormatter
      # ゲームシステムの識別子
      ID = 'CodeLayerd'

      # ゲームシステム名
      NAME = 'コード：レイヤード'

      # ゲームシステム名の読みがな
      SORT_KEY = 'こおとれいやあと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行為判定（nCL@m[c]+x または nCL+x@m[c]） クリティカル・ファンブル判定あり
          (ダイス数)CL+(修正値)@(判定値)[(クリティカル値)]+(修正値2)

          @m,[c],+xは省略可能。(@6[1]として処理)
          n個のD10でmを判定値、cをクリティカル値とした行為判定を行う。
          nが0以下のときはクリティカルしない1CL判定を行う。(1CL[0]と同一)
          例）
          7CL>=5 ：サイコロ7個で判定値6のロールを行い、目標値5に対して判定
          4CL@7  ：サイコロ4個で判定値7のロールを行い達成値を出す
          4CL+2@7 または 4CL@7+2  ：サイコロ4個で判定値7のロールを行い達成値を出し、修正値2を足す。
          4CL[2] ：サイコロ4個でクリティカル値2のロールを行う。
          0CL : 1CL[0]と同じ判定
      MESSAGETEXT

      register_prefix(['[+-]?\d*CL([+-]\d+)?[@\d]*.*'])

      def rollDiceCommand(command)
        debug('rollDiceCommand command', command)

        result = ''

        case command
        when /([+-]?\d+)?CL([+-]\d+)?(\@(\d))?(\[(\d+)\])?([+-]\d+)?(>=(\d+))?/i
          m = Regexp.last_match
          base = (m[1] || 1).to_i
          modifier1 = m[2].to_i
          target = (m[4] || 6).to_i
          criticalTarget = (m[6] || 1).to_i
          modifier2 = m[7].to_i
          diff = m[9].to_i
          result = checkRoll(base, target, criticalTarget, diff, modifier1 + modifier2)
        end

        return nil if result.empty?

        return "#{command} ＞ #{result}"
      end

      def checkRoll(base, target, criticalTarget, diff, modifier)
        result = ""

        base = getValue(base)
        target = getValue(target)
        criticalTarget = getValue(criticalTarget)
        if base <= 0
          criticalTarget = 0
          base = 1
        end

        target = 10 if target > 10

        result += "(#{base}d10#{format_modifier(modifier)})"

        _, diceText = roll(base, 10)

        diceList = diceText.split(/,/).map(&:to_i).sort

        result += " ＞ [#{diceList.join(',')}]#{format_modifier(modifier)} ＞ "
        result += getRollResultString(diceList, target, criticalTarget, diff, modifier)

        return result
      end

      def getRollResultString(diceList, target, criticalTarget, diff, modifier)
        successCount, criticalCount = getSuccessInfo(diceList, target, criticalTarget)

        successTotal = successCount + criticalCount + modifier
        result = ""

        result += "判定値[#{target}] " unless target == 6
        result += "クリティカル値[#{criticalTarget}] " unless criticalTarget == 1
        result += "達成値[#{successCount}]"

        # 出目がすべて判定値より大きければ固定値に関わらずファンブル
        if successCount <= 0
          result += " ＞ ファンブル！"
          return result
        end

        result += "+クリティカル[#{criticalCount}]" if criticalCount > 0
        result += format_modifier(modifier)
        result += "=[#{successTotal}]" if criticalCount > 0 || modifier != 0

        successText = getSuccessResultText(successTotal, diff)
        result += " ＞ #{successText}"

        return result
      end

      def getSuccessResultText(successTotal, diff)
        return successTotal.to_s if diff == 0
        return "成功" if successTotal >= diff

        return "失敗"
      end

      def getSuccessInfo(diceList, target, criticalTarget)
        debug("checkSuccess diceList, target, criticalTarget", diceList, target, criticalTarget)

        successCount  = 0
        criticalCount = 0

        diceList.each do |dice|
          successCount += 1 if dice <= target
          criticalCount += 1 if dice <= criticalTarget
        end

        return successCount, criticalCount
      end

      def getValue(number)
        return 0 if number > 100

        return number
      end
    end
  end
end
