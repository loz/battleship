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
      subject.new_game
    end

    describe :behaviour do
      before(:each) do
        @targets = []
        subject.stub(:last_shot_hit?).and_return(false)
      end

      it "should :get_shot" do
        subject.should_receive(:get_shot)

        subject.take_turn(@board, [])
      end

      it "should remember :last_shot" do
        expected = [3,6]
        subject.should_receive(:get_shot).and_return(expected)

        subject.take_turn(@board, [])

        subject.last_shot.should == expected
      end

      it "should save state" do 
        subject.take_turn(@board, [])

        subject.state.should == @board
      end

      context "when last_shot_hit" do
        before(:each) do
          subject.stub(:last_shot_hit?).and_return(true)
        end

        it "should add targets_around_last_shot to targets" do
          subject.stub(:targets_around_last_shot).and_return([[2,3],[:will,:pop]])

          subject.take_turn(@board, [])

          subject.instance_variable_get("@targets").should include [2,3]
        end
      end

      describe :get_shot do
        it "should get_random_shot" do
          subject.should_receive(:get_random_shot)
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

    describe :get_random_shot do
      it "should return a random x, y co-ordinate" do
        subject.rand.stub(:rand).and_return(5)
        subject.get_random_shot.should == [5,5]
      end
    end

    describe :search_for_ship do
      before(:each) do
        #a board full of *not* the ship
        @board = Array.new(10) do 
          Array.new(10, :miss)
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
