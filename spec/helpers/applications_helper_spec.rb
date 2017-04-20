require 'spec_helper'

describe ApplicationsHelper do
  before :each do
    authority = mock_model(Authority, full_name: "An authority", short_name: "Blue Mountains")
    @application = mock_model(Application, map_url: "http://a.map.url",
      description: "A planning application", council_reference: "A1", authority: authority, info_url: "http://info.url", comment_url: "http://comment.url",
      on_notice_from: nil, on_notice_to: nil)
  end

  describe "display_description_with_address" do
    before :each do
      allow(@application).to receive(:address).and_return("Foo Road, NSW")
    end

    context "when the application has no description" do
      before :each do
        allow(@application).to receive(:description).and_return(nil)
      end

      it "should add generic ‘application for’ text" do
        expect(helper.display_description_with_address(@application))
          .to eq "application for Foo Road, NSW"
      end
    end

    context "when the application has a description" do
      before :each do
        allow(@application).to receive(:description).and_return("Build something")
      end

      it {
        expect(helper.display_description_with_address(@application))
          .to eq "“Build something” at Foo Road, NSW"
      }

      it { expect(helper.display_description_with_address(@application)).to_not be html_safe? }
    end

    context "when the application has a description longer than 30 characters" do
      before :each do
        allow(@application).to receive(:description).and_return("Build something really really big")
      end

      it "should trucate the description" do
        expect(helper.display_description_with_address(@application))
          .to eq "“Build something really...” at Foo Road, NSW"
      end
    end

    context "when the application has a description with special characters" do
      before :each do
        allow(@application).to receive(:description).and_return("Alertations & additions")
      end

      it "should not escape them" do
        expect(helper.display_description_with_address(@application))
          .to eq "“Alertations & additions” at Foo Road, NSW"
      end
    end
  end

  describe "scraped_and_received_text" do
    before :each do
      allow(@application).to receive(:address).and_return("foo")
      allow(@application).to receive(:lat).and_return(1.0)
      allow(@application).to receive(:lng).and_return(2.0)
      allow(@application).to receive(:location).and_return(Location.new(1.0, 2.0))
    end

    it "should say when the application was received by the planning authority and when it appeared on PlanningAlerts" do
      allow(@application).to receive(:date_received).and_return(20.days.ago)
      allow(@application).to receive(:date_scraped).and_return(18.days.ago)
      expect(helper.scraped_and_received_text(@application)).to eq(
        "We found this application for you on the planning authority's website 18 days ago. It was received by them 2 days earlier."
      )
    end

    it "should say something appropriate when the received date is not known" do
      allow(@application).to receive(:date_received).and_return(nil)
      allow(@application).to receive(:date_scraped).and_return(18.days.ago)
      expect(helper.scraped_and_received_text(@application)).to eq(
        "We found this application for you on the planning authority's website 18 days ago. The date it was received by them was not recorded."
      )
    end
  end

  describe "decode" do
    it "should decode the html entities such as &amp; to &" do
      expect(decode("&#8211; &amp; &amp;#8217;")).to eq("– & ’")
    end
  end

  describe "on_notice_text" do
    before :each do
      allow(@application).to receive(:address).and_return("foo")
      allow(@application).to receive(:lat).and_return(1.0)
      allow(@application).to receive(:lng).and_return(2.0)
      allow(@application).to receive(:location).and_return(Location.new(1.0, 2.0))
      allow(@application).to receive(:date_received).and_return(nil)
      allow(@application).to receive(:date_scraped).and_return(Time.now)
    end

    it "should say when the application is on notice (and hasn't started yet)" do
      allow(@application).to receive(:on_notice_from).and_return(Date.today + 2.days)
      allow(@application).to receive(:on_notice_to).and_return(Date.today + 16.days)
      expect(helper.on_notice_text(@application)).to eq(
        "The period to have your comment officially considered by the planning authority <strong>starts in 2 days</strong> and finishes 14 days later."
      )
    end

    describe "period has just started" do
      it "should say when the application is on notice" do
        allow(@application).to receive(:on_notice_from).and_return(Date.today)
        allow(@application).to receive(:on_notice_to).and_return(Date.today + 14.days)
        expect(helper.on_notice_text(@application)).to eq(
          "<strong>You have 14 days left</strong> to have your comment officially considered by the planning authority. The period for comment started today."
        )
      end

      it "should say when the application is on notice" do
        allow(@application).to receive(:on_notice_from).and_return(Date.today - 1.day)
        allow(@application).to receive(:on_notice_to).and_return(Date.today + 13.days)
        expect(helper.on_notice_text(@application)).to eq(
          "<strong>You have 13 days left</strong> to have your comment officially considered by the planning authority. The period for comment started yesterday."
        )
      end
    end

    describe "period is in progress" do
      before :each do
        allow(@application).to receive(:on_notice_from).and_return(Date.today - 2.days)
        allow(@application).to receive(:on_notice_to).and_return(Date.today + 12.days)
      end

      it "should say when the application is on notice" do
        expect(helper.on_notice_text(@application)).to eq(
          "<strong>You have 12 days left</strong> to have your comment officially considered by the planning authority. The period for comment started 2 days ago."
        )
      end

      it "should only say when on notice to if there is no on notice from information" do
        allow(@application).to receive(:on_notice_from).and_return(nil)
        expect(helper.on_notice_text(@application)).to eq(
          "<strong>You have 12 days left</strong> to have your comment officially considered by the planning authority."
        )
      end
    end

    describe "period is finishing today" do
      it "should say when the application is on notice" do
        allow(@application).to receive(:on_notice_from).and_return(Date.today - 14.day)
        allow(@application).to receive(:on_notice_to).and_return(Date.today)
        expect(helper.on_notice_text(@application)).to eq(
          "<strong>Today is the last day</strong> to have your comment officially considered by the planning authority. The period for comment started 14 days ago."
        )
      end
    end

    describe "period is finished" do
      before :each do
        allow(@application).to receive(:on_notice_from).and_return(Date.today - 16.days)
        allow(@application).to receive(:on_notice_to).and_return(Date.today - 2.days)
      end

      it "should say when the application is on notice" do
        expect(helper.on_notice_text(@application)).to eq(
          "You're too late! The period for officially commenting on this application <strong>finished 2 days ago</strong>. It lasted for 14 days. If you chose to comment now, your comment will still be displayed here and be sent to the planning authority but it will <strong>not be officially considered</strong> by the planning authority."
        )
      end

      it "should only say when on notice to if there is no on notice from information" do
        allow(@application).to receive(:on_notice_from).and_return(nil)
        expect(helper.on_notice_text(@application)).to eq(
          "You're too late! The period for officially commenting on this application <strong>finished 2 days ago</strong>. If you chose to comment now, your comment will still be displayed here and be sent to the planning authority but it will <strong>not be officially considered</strong> by the planning authority."
        )
      end
    end

    describe "static maps" do
      before :each do
        allow(@application).to receive(:address).and_return("Foo Road, NSW")
      end

      it "should generate a static google map api image" do
        expect(helper.google_static_map(@application, size: "350x200", zoom: 16)).to eq(
          "<img alt=\"Map of Foo Road, NSW\" src=\"https://maps.googleapis.com/maps/api/staticmap?zoom=16&size=350x200&maptype=roadmap&markers=color:red%7C1.0,2.0\" width=\"350\" height=\"200\" />"
        )
        expect(helper.google_static_map(@application, size: "100x100", zoom: 14)).to eq(
          "<img alt=\"Map of Foo Road, NSW\" src=\"https://maps.googleapis.com/maps/api/staticmap?zoom=14&size=100x100&maptype=roadmap&markers=color:red%7C1.0,2.0\" width=\"100\" height=\"100\" />"
        )
      end
    end

    describe "static streetview" do
      before :each do
        allow(@application).to receive(:address).and_return("Foo Road, NSW")
      end

      it "should generate a static google streetview image" do
        expect(helper.google_static_streetview(@application, size: "350x200", fov: 90)).to eq(
          "<img alt=\"Streetview of Foo Road, NSW\" src=\"https://maps.googleapis.com/maps/api/streetview?size=350x200&location=1.0,2.0&fov=90\" width=\"350\" height=\"200\" />"
        )
        expect(helper.google_static_streetview(@application, size: "100x100", fov: 60)).to eq(
          "<img alt=\"Streetview of Foo Road, NSW\" src=\"https://maps.googleapis.com/maps/api/streetview?size=100x100&location=1.0,2.0&fov=60\" width=\"100\" height=\"100\" />"
        )
      end
    end
  end
end
