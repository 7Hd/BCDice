require "bcdice/normalize"
require "bcdice/format"

module BCDice
  module CommonCommand
    # 個数振り足しダイス
    #
    # ダイスを振り、条件を満たした出目の個数だけダイスを振り足す。振り足しがなくなるまでこれを繰り返す。
    # 成功条件を満たす出目の個数を調べ、成功数を表示する。
    #
    # 例
    #   2R6+1R10[>3]>=5
    #   2R6+1R10>=5@>3
    #
    # 振り足し条件は角カッコかコマンド末尾の @ で指定する。
    # [>3] の場合、3より大きい出目が出たら振り足す。
    # [3] のように数値のみ指定されている場合、成功条件の比較演算子を流用する。
    # 上記の例の時、出目が
    #   "2R6"  -> [5,6] [5,4] [1,3]
    #   "1R10" -> [9] [1]
    # だとすると、 >=5 に該当するダイスは5つなので成功数5となる。
    #
    # 成功条件が書かれていない場合、成功数0として扱う。
    # 振り足し条件が数値のみ指定されている場合、比較演算子は >= が指定されたとして振舞う。
    class RerollDice
      REROLL_LIMIT = 10000

      def initialize(command, bcdice, diceBot)
        @command = command
        @bcdice = bcdice
        @diceBot = diceBot

        @is_secret = false
      end

      def secret?
        @is_secret
      end

      def eval()
        unless parse(@command)
          return nil
        end

        unless @reroll_threshold
          return msg_invalid_reroll_number(@command)
        end

        dice_queue = @notation.split("+").map do |xRn|
          x, n = xRn.split("R").map(&:to_i)
          [x, n, 0]
        end

        unless dice_queue.all? { |d| valid_reroll_rule?(d[1], @reroll_cmp_op, @reroll_threshold) }
          return msg_invalid_reroll_number(@command)
        end

        success_count = 0
        dice_str_list = []
        one_count = 0
        loop_count = 0

        dice_total_count = 0

        while !dice_queue.empty? && loop_count < REROLL_LIMIT
          # xRn
          x, n, depth = dice_queue.shift
          loop_count += 1
          dice_total_count += x

          dice_list = @bcdice.roll_barabara(x, n)
          dice_list.sort! if @diceBot.sort_barabara_dice?
          success_count += dice_list.count() { |val| compare(val, @cmp_op, @target_number) } if @cmp_op
          reroll_count = dice_list.count() { |val| compare(val, @reroll_cmp_op, @reroll_threshold) }

          dice_str_list.push(dice_list.join(","))

          if depth.zero?
            one_count += dice_list.count(1)
          end

          if reroll_count > 0
            dice_queue.push([reroll_count, n, depth + 1])
          end
        end

        sequence = [
          expr(),
          dice_str_list.join(" + "),
          "成功数#{success_count}",
          @diceBot.grich_text(one_count, dice_total_count, success_count),
        ].compact

        return ": #{sequence.join(' ＞ ')}"
      end

      private

      # @param command [String]
      # @return [Boolean]
      def parse(command)
        m = /^S?(\d+R\d+(?:\+\d+R\d+)*)(?:\[([<>=]+)?(\d+)\])?(?:([<>=]+)(\d+))?(?:@([<>=]+)?(\d+))?$/.match(command)
        unless m
          return false
        end

        @is_secret = command.start_with?("S")
        @notation = m[1]
        @cmp_op = Normalize.comparison_operator(m[4]) || @diceBot.default_cmp_op
        @target_number = m[5]&.to_i || @diceBot.default_target_number

        @reroll_cmp_op = decide_reroll_cmp_op(m)
        @reroll_threshold = decide_reroll_threshold(m[3] || m[7], @target_number)

        return true
      end

      # @param m [MatchData]
      # @return [Symbol]
      def decide_reroll_cmp_op(m)
        bracket_op = m[2]
        bracket_number = m[3]
        at_op = m[6]
        at_number = m[7]
        cmp_op = m[4]

        op =
          if bracket_op && bracket_number
            bracket_op
          elsif at_op && at_number
            at_op
          else
            cmp_op
          end

        Normalize.comparison_operator(op) || :>=
      end

      # @param captured_threshold [String, nil]
      # @param target_number [Integer, nil]
      # @return [Integer]
      # @return [nil]
      def decide_reroll_threshold(captured_threshold, target_number)
        if captured_threshold
          captured_threshold.to_i
        elsif @diceBot.reroll_dice_reroll_threshold
          @diceBot.reroll_dice_reroll_threshold
        else
          target_number
        end
      end

      # @return [String]
      def expr()
        reroll_cmp_op_text = @cmp_op != @reroll_cmp_op ? Format.comparison_operator(@reroll_cmp_op) : nil
        cmp_op_text = Format.comparison_operator(@cmp_op)

        "(#{@notation}[#{reroll_cmp_op_text}#{@reroll_threshold}]#{cmp_op_text}#{@target_number})"
      end

      # @param command [String]
      # @return [String]
      def msg_invalid_reroll_number(command)
        ": #{command} ＞ 条件が間違っています。2R6>=5 あるいは 2R6[5] のように振り足し目標値を指定してください。"
      end

      # @param sides [Integer]
      # @param cmp_op [Symbol]
      # @param reroll_threshold [Integer]
      # @return [Boolean]
      def valid_reroll_rule?(sides, cmp_op, reroll_threshold) # 振り足しロールの条件確認
        case cmp_op
        when :<=
          reroll_threshold < sides
        when :<
          reroll_threshold <= sides
        when :>=
          reroll_threshold > 1
        when :>
          reroll_threshold >= 1
        when :'!='
          (1..sides).include?(reroll_threshold)
        else
          true
        end
      end

      # @param prefix [String]
      # @param string [String]
      # @param [String, nil]
      def trim_prefix(prefix, string)
        if string.start_with?(prefix)
          string = string[prefix.size..-1]
        end

        if string.empty?
          nil
        else
          string
        end
      end

      # 整数を比較する
      # Ruby 1.8のケア用
      #
      # @param lhs [Integer]
      # @param op [Symbol]
      # @param rhs [Integer]
      # @return [Boolean]
      def compare(lhs, op, rhs)
        if op == :'!='
          lhs != rhs
        else
          lhs.send(op, rhs)
        end
      end
    end
  end
end
