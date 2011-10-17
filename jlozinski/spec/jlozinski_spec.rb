require File.expand_path(__FILE__ + '/../../jlozinski.rb')

describe JLozinskiPlayer do

  describe :initialized do
    it "should setup a Random on #rand" do
      subject.rand.should be_a Random
    end
  end

  describe :new_game do
    it "should return fixed player board for now" do

    subject.new_game.should == [
      [3, 0, 5, :across],
      [0, 2, 4, :down],
      [6, 5, 3, :across],
      [2, 6, 3, :down],
      [8, 8, 2, :across]
    ]
    end
  end

  describe :take_turn do

    before(:each) do
      @board = Array.new(10) do 
        Array.new(10, :unknown)
      end
      @ships = [5,2]
      subject.new_game
    end

    describe :behaviour do
      before(:each) do
        @targets = []
        subject.stub(:last_shot_hit?).and_return(false)
      end

      it "should :get_shot" do
        subject.should_receive(:get_shot)

        subject.take_turn(@board, @ships)
      end

      it "should remember :last_shot" do
        expected = [3,6]
        subject.should_receive(:get_shot).and_return(expected)

        subject.take_turn(@board, @ships)

        subject.last_shot.should == expected
      end

      it "should save state" do 
        subject.take_turn(@board, @ships)

        subject.state.should == @board
      end

      it "should save ships_to_find" do
        expected = [1,2,3]
        subject.stub(:ship_hit).and_return(false)
        subject.take_turn(@board, expected)

        subject.ships_to_find.should == expected
      end

      context "when last_shot_hit" do
        before(:each) do
          subject.instance_variable_set('@hits_in_target', 1)
          subject.stub(:ship_hit).and_return(5)
          subject.stub(:last_shot_hit?).and_return(true)
        end

        it "should increment 'hits in current targets'" do
          subject.instance_variable_set('@hits_in_target', 0)
          subject.stub(:targets_around_last_shot).and_return []
          subject.stub(:ship_hit).and_return(false)
          subject.take_turn(@board, @ships)
    
          subject.instance_variable_get('@hits_in_target').should == 1
        end

        describe "when battleship destroyed" do
          before(:each) do
            @hits = 4
            subject.stub(:targets_around_last_shot).and_return []
            subject.instance_variable_set('@hits_in_target', @hits)
            subject.instance_variable_set("@targets", [[1,1], [2,2]])
            subject.stub(:ship_hit).and_return(5)
            subject.stub(:get_shot).and_return []
          end

          it "should stop hunting around targets" do
            subject.take_turn(@board, @ships_after)

            subject.instance_variable_get("@targets").should be_empty
          end

          context "and hit in target are more than the size of the destroyed ship" do
            before(:each) do
              @ships_before = [3,2]
              @ships_after = [3]
              @hits = 3

              subject.instance_variable_set('@hits_in_target', @hits)
              subject.instance_variable_set("@ships_to_find", @ships_before)
              subject.instance_variable_set("@targets", [[1,1], [2,2]])
            end

            it "should NOT reset targets" do
              subject.take_turn(@board, @ships_after)

              subject.instance_variable_get("@targets").should_not be_empty
            end
          end
        end

        describe "when ship not fully destroyed" do
          before(:each) do
            subject.instance_variable_set("@ships_to_find", @ships)
          end

          it "should add targets_around_last_shot to targets" do
            subject.stub(:targets_around_last_shot).and_return([[2,3],[:will,:pop]])

            subject.take_turn(@board, @ships)

            subject.instance_variable_get("@targets").should include [2,3]
          end
        end

      end

      describe :ship_hit do
        before(:each) do
          @ships = [5,4,3,3,2]
          @change5 = [4,3,3,2]
          @change3 = [5,4,3,2]
        end

        it "should return nil if no change" do
          subject.instance_variable_set('@ships_to_find', @ships)
          subject.ship_hit(@ships).should be_nil
        end

        it "should return 5 when 5 changed" do
          subject.instance_variable_set('@ships_to_find', @ships)
          subject.ship_hit(@change5).should == 5
        end

        it "should return 3 when 3 changed" do
          subject.instance_variable_set('@ships_to_find', @ships)
          subject.ship_hit(@change3).should == 3
        end
      end

      describe :get_shot do
        it "should get_likely_shot" do
          subject.should_receive(:get_likely_shot)
          subject.get_shot
        end

        context "when there are targets" do
          before(:each) do
            @targets = [[1,1],[2,2]]
            subject.instance_variable_set('@targets', @targets)
          end

          it "should pop a target off the list for the shot" do
            shot = subject.get_shot
            shot.should == [2,2]
            subject.instance_variable_get('@targets').should == [[1,1]]
          end
        end
      end

    end

    describe :get_likely_shot do
      before(:each) do
        @heatmap = Array.new(10) do
          Array.new(10, 0)
        end
        subject.stub(:ships_to_find).and_return([5,2])
      end

      it "find possible shots for largest remaining ship" do
        subject.should_receive(:possible_shots_for_ship).with(5).and_return([])
        subject.take_turn(@board, @ships)
      end

      it "should generate a heatmap from the posible locations" do
        targets = [1,2,3]
        subject.stub(:possible_shots_for_ship).and_return(targets)
        subject.should_receive(:build_heatmap).with(targets).and_return(@heatmap)
        subject.take_turn(@board, @ships)
      end

      it "should find hottest in heatmap and pick one from set" do
        subject.stub(:build_heatmap).and_return(@heatmap)
        hottest = [1,2,3]
        expected = [[1,2]]
        subject.should_receive(:find_hottest).with(@heatmap).and_return(hottest)
        hottest.should_receive(:sample).with(1).and_return(expected)
        subject.take_turn(@board, @ships).should == expected.first
      end

      describe :find_hottest do
        it "should return the hottest item(s)" do
          @heatmap[1][2] = 5
          subject.find_hottest(@heatmap).should == [[2,1]]
          @heatmap[4][2] = 6
          @heatmap[7][2] = 6
          subject.find_hottest(@heatmap).should == [[2,4],[2,7]]
        end
      end
    end

    describe :search_for_ship do

      describe :possible_locations_in_row do
        it "should return an array of the possible locations in a given row" do
          row = [:unknown, :unknown, :unknown]
          ship = 2
          expected = [0, 1]

          subject.possible_locations_in_row(row, ship).should == expected
        end
      end

      describe :possible_locations_for_ship do
        before(:each) do
          subject.stub(:state).and_return([
            [:unknown, :unknown, :unknown],
            [:unknown, :unknown, :unknown],
            [:unknown, :unknown, :unknown]
          ])
        end


        it "should work out possible locations in row for each row" do
          subject.should_receive(:possible_locations_in_row).exactly(3).times.and_return([])

          subject.possible_locations_for_ship(2)
        end

        it "should return array of x,y found in each row" do
          result = subject.possible_locations_for_ship(2)
          result.should include [0,0]
          result.should include [0,1]
        end

        it "should also work through columns" do
          result = subject.possible_locations_for_ship(2, :down)
          result.should include [2,0]
          result.should include [2,1]
        end
      end

      describe :parts_for_ship do
        it "should give co-ords for ship of given size, x,y and orientation" do
          subject.parts_for_ship(2, 0, 0, :across).should == [
            [0,0], [1,0]
          ]
          subject.parts_for_ship(2, 0, 0, :down).should == [
            [0,0], [0,1]
          ]
        end
      end
      describe :possible_shots_for_ship do

        describe :build_heatmap do
          it "should be 0 for no given target" do
            subject.build_heatmap([])[1][1].should == 0
          end

          it "should be count for count targets" do
            t = [ [1,1], [1,1] ]
            subject.build_heatmap(t)[1][1].should == 2
          end
        end

        it "should find the shots for the locations" do
          subject.stub(:possible_locations_for_ship).and_return([[0,0]])
          subject.should_receive(:parts_for_ship).with(2, 0, 0, :across).and_return([])
          subject.should_receive(:parts_for_ship).with(2, 0, 0, :down).and_return([])
          subject.possible_shots_for_ship(2)
        end

        it "should also seach vertical possiblities" do
          subject.stub(:possible_locations_for_ship).and_return([[0,0]])
          subject.should_receive(:parts_for_ship).with(2, 0, 0, :across).and_return([])
          subject.should_receive(:parts_for_ship).with(2, 0, 0, :down).and_return([])
          subject.possible_shots_for_ship(2)
        end
      end

    end
    
    describe :last_shot_hit? do
      
      context "When last shot is nil" do
        before(:each) do
          subject.instance_variable_set("@last_shot", nil)
        end

        it "should return false" do
          subject.last_shot_hit?.should == false
        end
      end

      context "When I have played a shot" do
        before(:each) do
          subject.stub(:last_shot).and_return([3,6])
        end

        context "and the board shows :hit at last shot" do
          before(:each) do
            @board[6][3] = :hit
            subject.stub(:state).and_return(@board)
          end

          it "should return true" do
            subject.last_shot_hit?.should == true
          end
        end

        context "and the board shows :miss at the last shot" do
          before(:each) do
            @board[6][3] = :miss
            subject.stub(:state).and_return(@board)
          end

          it "should return false" do
            subject.last_shot_hit?.should == false
          end
        end
      end

    end
    
    describe :stringify_row do
      it "should convert :unknowns to U" do
        subject.stringify_row([:unknown]).should == "U"
      end

      it "should convert :miss to M" do
        subject.stringify_row([:miss]).should == "M"
      end

      it "should convert :hit to H" do
        subject.stringify_row([:hit]).should == "H"
      end
    end

    describe :targets_around_last_shot do
      before(:each) do
        subject.stub(:last_shot).and_return([6,3])
        subject.stub(:state).and_return(@board)
      end

      describe "when up is not :unknown" do
        before(:each) do
          @board[2][6] = :miss
          subject.stub(:state).and_return(@board)
        end

        it "should not include up" do
          subject.targets_around_last_shot.should_not include [6,2]
        end
      end

      describe "when down is not :unknown" do
        before(:each) do
          @board[4][6] = :miss
          subject.stub(:state).and_return(@board)
        end

        it "should not include down" do
          subject.targets_around_last_shot.should_not include [6,4]
        end
      end

      describe "when left is not :unknown" do
        before(:each) do
          @board[3][5] = :miss
          subject.stub(:state).and_return(@board)
        end

        it "should not include left" do
          subject.targets_around_last_shot.should_not include [5,3]
        end
      end

      describe "when right is not :unknown" do
        before(:each) do
          @board[3][7] = :miss
          subject.stub(:state).and_return(@board)
        end

        it "should not include right" do
          subject.targets_around_last_shot.should_not include [7,3]
        end
      end

      it "should include up down left right of last shot" do
        subject.targets_around_last_shot.should include [5,3]
        subject.targets_around_last_shot.should include [7,3]
        subject.targets_around_last_shot.should include [6,4]
        subject.targets_around_last_shot.should include [6,2]
        subject.targets_around_last_shot.should have(4).items
      end

      describe "when shot is a top of board" do
        before(:each) do
          subject.stub(:last_shot).and_return([6,0])
        end

        it "should just be left, right and below" do
          subject.targets_around_last_shot.should include [5,0]
          subject.targets_around_last_shot.should include [7,0]
          subject.targets_around_last_shot.should include [6,1]
          subject.targets_around_last_shot.should have(3).items
        end
      end

      describe "when shot is at bottom of board" do
        before(:each) do
          subject.stub(:last_shot).and_return([6,9])
        end

        it "should just be left, right and above" do
          subject.targets_around_last_shot.should include [5,9]
          subject.targets_around_last_shot.should include [7,9]
          subject.targets_around_last_shot.should include [6,8]
          subject.targets_around_last_shot.should have(3).items
        end
      end

      describe "when shot is at left of board" do
        before(:each) do
          subject.stub(:last_shot).and_return([0,6])
        end

        it "should just be above below and right" do
          subject.targets_around_last_shot.should include [0,5]
          subject.targets_around_last_shot.should include [0,7]
          subject.targets_around_last_shot.should include [1,6]
          subject.targets_around_last_shot.should have(3).items
        end
      end

      describe "when shot is at right of board" do
        before(:each) do
          subject.stub(:last_shot).and_return([9,6])
        end

        it "should just be above below and left" do
          subject.targets_around_last_shot.should include [9,5]
          subject.targets_around_last_shot.should include [9,7]
          subject.targets_around_last_shot.should include [8,6]
          subject.targets_around_last_shot.should have(3).items
        end
      end
    end
  end

end
