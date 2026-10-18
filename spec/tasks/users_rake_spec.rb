require "rails_helper"
require "rake"

RSpec.describe "users:create" do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  def run_task(*lines)
    task = Rake::Task["users:create"]
    task.reenable
    original_stdin = $stdin
    $stdin = StringIO.new(lines.join("\n") + "\n")
    task.invoke
  ensure
    $stdin = original_stdin
  end

  it "creates an account from the prompted email address and password" do
    expect { run_task("listener@example.com", "a long passphrase", "a long passphrase") }
      .to output(/Created listener@example\.com\./).to_stdout
      .and change(User, :count).by(1)

    expect(User.authenticate_by(email_address: "listener@example.com", password: "a long passphrase")).to be_present
  end

  it "stops when the two passwords differ" do
    expect { run_task("listener@example.com", "a long passphrase", "a different one") }
      .to raise_error(SystemExit)
      .and output(/don't match/).to_stderr
      .and output.to_stdout

    expect(User.count).to eq(0)
  end

  it "stops when the password is too short" do
    expect { run_task("listener@example.com", "short", "short") }
      .to raise_error(SystemExit)
      .and output(/Password is too short/).to_stderr
      .and output.to_stdout

    expect(User.count).to eq(0)
  end

  it "stops when the email address already has an account" do
    create(:user, email_address: "listener@example.com")

    expect { run_task("listener@example.com", "a long passphrase", "a long passphrase") }
      .to raise_error(SystemExit)
      .and output(/already exists/).to_stderr
      .and output.to_stdout
  end
end
